# typed: strict
# frozen_string_literal: true

require "rbi"

module Spoom
  module Sorbet
    class Sigs
      class Error < Spoom::Error; end
      class << self
        #: (String ruby_contents) -> String
        def strip(ruby_contents)
          sigs = collect_sorbet_sigs(ruby_contents)
          lines_to_strip = sigs.flat_map { |sig, _| (sig.loc&.begin_line..sig.loc&.end_line).to_a }

          lines = []
          ruby_contents.lines.each_with_index do |line, index|
            lines << line unless lines_to_strip.include?(index + 1)
          end
          lines.join
        end

        #: (String ruby_contents, positional_names: bool) -> String
        def rbi_to_rbs(ruby_contents, positional_names: true)
          ruby_contents = ruby_contents.dup
          sigs = collect_sorbet_sigs(ruby_contents)

          sigs.each do |sig, node|
            scanner = Scanner.new(ruby_contents)
            start_index = scanner.find_char_position(
              T.must(sig.loc&.begin_line&.pred),
              T.must(sig.loc).begin_column,
            )
            end_index = scanner.find_char_position(
              sig.loc&.end_line&.pred,
              T.must(sig.loc).end_column,
            )
            rbs = RBIToRBSTranslator.translate(sig, node, positional_names: positional_names)
            ruby_contents[start_index...end_index] = rbs
          end

          ruby_contents
        end

        #: (String ruby_contents) -> String
        def rbs_to_rbi(ruby_contents)
          ruby_contents = ruby_contents.dup
          rbs_comments = collect_rbs_comments(ruby_contents)

          rbs_comments.each do |rbs_comment, node|
            scanner = Scanner.new(ruby_contents)
            start_index = scanner.find_char_position(
              T.must(rbs_comment.loc&.begin_line&.pred),
              T.must(rbs_comment.loc).begin_column,
            )
            end_index = scanner.find_char_position(
              rbs_comment.loc&.end_line&.pred,
              T.must(rbs_comment.loc).end_column,
            )
            rbi = RBSToRBITranslator.translate(rbs_comment, node)
            next unless rbi

            ruby_contents[start_index...end_index] = rbi
          end

          ruby_contents
        end

        private

        #: (String ruby_contents) -> Array[[RBI::Sig, (RBI::Method | RBI::Attr)]]
        def collect_sorbet_sigs(ruby_contents)
          tree = RBI::Parser.parse_string(ruby_contents)
          visitor = SigsLocator.new
          visitor.visit(tree)
          visitor.sigs.sort_by { |sig, _node| -T.must(sig.loc&.begin_line) }
        end

        #: (String ruby_contents) -> Array[[RBI::RBSComment, (RBI::Method | RBI::Attr)]]
        def collect_rbs_comments(ruby_contents)
          tree = RBI::Parser.parse_string(ruby_contents)
          visitor = SigsLocator.new
          visitor.visit(tree)
          visitor.rbs_comments.sort_by { |comment, _node| -T.must(comment.loc&.begin_line) }
        end
      end

      class SigsLocator < RBI::Visitor
        #: Array[[RBI::Sig, (RBI::Method | RBI::Attr)]]
        attr_reader :sigs

        #: Array[[RBI::RBSComment, (RBI::Method | RBI::Attr)]]
        attr_reader :rbs_comments

        #: -> void
        def initialize
          super
          @sigs = [] #: Array[[RBI::Sig, (RBI::Method | RBI::Attr)]]
          @rbs_comments = [] #: Array[[RBI::RBSComment, (RBI::Method | RBI::Attr)]]
        end

        # @override
        #: (RBI::Node? node) -> void
        def visit(node)
          return unless node

          case node
          when RBI::Method, RBI::Attr
            node.sigs.each do |sig|
              next if sig.is_abstract

              @sigs << [sig, node]
            end
            node.comments.grep(RBI::RBSComment).each do |rbs_comment|
              @rbs_comments << [rbs_comment, node]
            end
          when RBI::Tree
            visit_all(node.nodes)
          end
        end
      end

      class RBIToRBSTranslator
        class << self
          #: (RBI::Sig sig, (RBI::Method | RBI::Attr) node, positional_names: bool) -> String
          def translate(sig, node, positional_names: true)
            case node
            when RBI::Method
              translate_method_sig(sig, node, positional_names: positional_names)
            when RBI::Attr
              translate_attr_sig(sig, node, positional_names: positional_names)
            end
          end

          private

          #: (RBI::Sig sig, RBI::Method node, positional_names: bool) -> String
          def translate_method_sig(sig, node, positional_names: true)
            out = StringIO.new
            p = RBI::RBSPrinter.new(out: out, indent: sig.loc&.begin_column, positional_names: positional_names)

            if sig.without_runtime
              p.printn("# @without_runtime")
              p.printt
            end

            if node.sigs.any?(&:is_final)
              p.printn("# @final")
              p.printt
            end

            if node.sigs.any?(&:is_abstract)
              p.printn("# @abstract")
              p.printt
            end

            if node.sigs.any?(&:is_override)
              if node.sigs.any?(&:allow_incompatible_override)
                p.printn("# @override(allow_incompatible: true)")
              else
                p.printn("# @override")
              end
              p.printt
            end

            if node.sigs.any?(&:is_overridable)
              p.printn("# @overridable")
              p.printt
            end

            p.print("#: ")
            p.send(:print_method_sig, node, sig)

            out.string
          end

          #: (RBI::Sig sig, RBI::Attr node, positional_names: bool) -> String
          def translate_attr_sig(sig, node, positional_names: true)
            out = StringIO.new
            p = RBI::RBSPrinter.new(out: out, positional_names: positional_names)
            p.print_attr_sig(node, sig)
            "#: #{out.string}"
          end
        end
      end

      class RBSToRBITranslator
        class << self
          extend T::Sig

          #: (RBI::RBSComment comment, (RBI::Method | RBI::Attr) node) -> String?
          def translate(comment, node)
            case node
            when RBI::Method
              translate_method_sig(comment, node)
            when RBI::Attr
              translate_attr_sig(comment, node)
            end
          rescue RBS::ParsingError
            nil
          end

          private

          #: (RBI::RBSComment rbs_comment, RBI::Method node) -> String
          def translate_method_sig(rbs_comment, node)
            method_type = ::RBS::Parser.parse_method_type(rbs_comment.text)
            translator = RBI::RBS::MethodTypeTranslator.new(node)
            translator.visit(method_type)

            # TODO: move this to `rbi`
            res = translator.result
            node.comments.each do |comment|
              case comment.text
              when "@abstract"
                res.is_abstract = true
              when "@final"
                res.is_final = true
              when "@override"
                res.is_override = true
              when "@override(allow_incompatible: true)"
                res.is_override = true
                res.allow_incompatible_override = true
              when "@overridable"
                res.is_overridable = true
              when "@without_runtime"
                res.without_runtime = true
              end
            end

            res.string.strip
          end

          #: (RBI::RBSComment comment, RBI::Attr node) -> String
          def translate_attr_sig(comment, node)
            attr_type = ::RBS::Parser.parse_type(comment.text)
            sig = RBI::Sig.new

            if node.is_a?(RBI::AttrWriter)
              if node.names.size != 1
                raise Error, "AttrWriter must have exactly one name"
              end

              name = T.must(node.names.first)
              sig.params << RBI::SigParam.new(name.to_s, RBI::RBS::TypeTranslator.translate(attr_type))
            end

            sig.return_type = RBI::RBS::TypeTranslator.translate(attr_type)
            sig.string.strip
          end
        end
      end

      # From https://github.com/Shopify/ruby-lsp/blob/9154bfc6ef/lib/ruby_lsp/document.rb#L127
      class Scanner
        LINE_BREAK = 0x0A #: Integer

        #: (String source) -> void
        def initialize(source)
          @current_line = 0 #: Integer
          @pos = 0 #: Integer
          @source = source.codepoints #: Array[Integer]
        end

        # Finds the character index inside the source string for a given line and column
        #: (Integer line, Integer character) -> Integer
        def find_char_position(line, character)
          # Find the character index for the beginning of the requested line
          until @current_line == line
            @pos += 1 until LINE_BREAK == @source[@pos]
            @pos += 1
            @current_line += 1
          end

          # The final position is the beginning of the line plus the requested column
          @pos + character
        end
      end
    end
  end
end

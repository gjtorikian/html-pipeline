# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks for blank lines after signatures.
      #
      # @example
      #   # bad
      #   sig { void }
      #
      #   def foo; end
      #
      #   # good
      #   sig { void }
      #   def foo; end
      class EmptyLineAfterSig < ::RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp
        include SignatureHelp

        MSG = "Extra empty line or comment detected"

        # @!method sig_or_signable_method_definition?(node)
        def_node_matcher :sig_or_signable_method_definition?, <<~PATTERN
          ${
            any_def
            (send nil? {:attr :attr_reader :attr_writer :attr_accessor} ...)
            #signature?
          }
        PATTERN

        def on_signature(sig)
          sig_or_signable_method_definition?(next_sibling(sig)) do |definition|
            range = lines_between(sig, definition)
            next if range.empty? || range.single_line? || contains_only_rubocop_directives?(range)

            add_offense(range) do |corrector|
              lines = range.source.lines
              rubocop_lines, other_lines = lines.partition { |line| line.strip.start_with?("# rubocop:") }

              unless other_lines.empty?
                corrector.insert_before(
                  range_by_whole_lines(sig.source_range),
                  other_lines.join
                    .sub(/\A\n+/, "") # remove initial newline(s)
                    .gsub(/\n{2,}/, "\n"), # remove empty line(s)
                )
              end

              corrector.replace(range, rubocop_lines.empty? ? "" : rubocop_lines.join)
            end
          end
        end

        private

        def next_sibling(node)
          node.parent&.children&.at(node.sibling_index + 1)
        end

        def contains_only_rubocop_directives?(range)
          range.source.lines.all? { |line| line.strip.start_with?("# rubocop:") }
        end

        def lines_between(node1, node2, buffer: processed_source.buffer)
          end_of_node1_pos   = node1.source_range.end_pos
          start_of_node2_pos = node2.source_range.begin_pos

          string_in_between = buffer.slice(end_of_node1_pos...start_of_node2_pos)
          # Fallbacks handle same line edge case
          begin_offset = string_in_between.index("\n")  || 0
          end_offset   = string_in_between.rindex("\n") || string_in_between.length - 1

          Parser::Source::Range.new(
            buffer,
            end_of_node1_pos + begin_offset + 1, # +1 to exclude post-node1 newline
            end_of_node1_pos + end_offset   + 1, # +1 to include pre-node2  newline
          )
        end
      end
    end
  end
end

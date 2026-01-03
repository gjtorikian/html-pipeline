# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    # Translate all RBS signature comments to Sorbet RBI signatures
    class TranslateRBSSigs < Visitor
      class Error < RBI::Error; end

      # @override
      #: (Node? node) -> void
      def visit(node)
        return unless node

        case node
        when Tree
          visit_all(node.nodes)
        when AttrAccessor, AttrReader, AttrWriter
          rbs_comments = extract_rbs_comments(node)
          rbs_comments.each do |comment|
            node.sigs << translate_rbs_attr_type(node, comment)
          end
        when Method
          rbs_comments = extract_rbs_comments(node)
          rbs_comments.each do |comment|
            node.sigs << translate_rbs_method_type(node, comment)
          end
        end
      end

      private

      #: (Method | Attr) -> Array[RBSComment]
      def extract_rbs_comments(node)
        comments = node.comments.dup
        node.comments.clear

        rbs_sigs = [] #: Array[RBSComment]

        comments.each do |comment|
          case comment
          when RBSComment
            rbs_sigs << comment
          else
            node.comments << comment
          end
        end

        rbs_sigs
      end

      #: (Method, RBSComment) -> Sig
      def translate_rbs_method_type(node, comment)
        method_type = ::RBS::Parser.parse_method_type(comment.text)
        translator = RBS::MethodTypeTranslator.new(node)
        translator.visit(method_type)
        translator.result
      end

      #: (Attr, RBSComment) -> Sig
      def translate_rbs_attr_type(node, comment)
        attr_type = ::RBS::Parser.parse_type(comment.text)
        sig = Sig.new

        if node.is_a?(AttrWriter)
          if node.names.size != 1
            raise Error, "AttrWriter must have exactly one name"
          end

          name = node.names.first #: as !nil
          sig.params << SigParam.new(name.to_s, RBS::TypeTranslator.translate(attr_type))
        end

        sig.return_type = RBS::TypeTranslator.translate(attr_type)
        sig
      end
    end
  end

  class Tree
    #: -> void
    def translate_rbs_sigs!
      visitor = Rewriters::TranslateRBSSigs.new
      visitor.visit(self)
    end
  end
end

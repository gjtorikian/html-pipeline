# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    class Deannotate < Visitor
      #: (String annotation) -> void
      def initialize(annotation)
        super()
        @annotation = annotation
      end

      # @override
      #: (Node? node) -> void
      def visit(node)
        case node
        when Scope, Const, Attr, Method, TStructField, TypeMember
          deannotate_node(node)
        end
        visit_all(node.nodes) if node.is_a?(Tree)
      end

      private

      #: (NodeWithComments node) -> void
      def deannotate_node(node)
        return unless node.annotations.one?(@annotation)

        node.comments.reject! do |comment|
          comment.text == "@#{@annotation}"
        end
      end
    end
  end

  class Tree
    #: (String annotation) -> void
    def deannotate!(annotation)
      visitor = Rewriters::Deannotate.new(annotation)
      visitor.visit(self)
    end
  end
end

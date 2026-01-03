# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    class Annotate < Visitor
      #: (String annotation, ?annotate_scopes: bool, ?annotate_properties: bool) -> void
      def initialize(annotation, annotate_scopes: false, annotate_properties: false)
        super()
        @annotation = annotation
        @annotate_scopes = annotate_scopes
        @annotate_properties = annotate_properties
      end

      # @override
      #: (Node? node) -> void
      def visit(node)
        case node
        when Scope
          annotate_node(node) if @annotate_scopes || root?(node)
        when Const, Attr, Method, TStructField, TypeMember
          annotate_node(node) if @annotate_properties
        end
        visit_all(node.nodes) if node.is_a?(Tree)
      end

      private

      #: (NodeWithComments node) -> void
      def annotate_node(node)
        return if node.annotations.one?(@annotation)

        node.comments << Comment.new("@#{@annotation}")
      end

      #: (Node node) -> bool
      def root?(node)
        parent = node.parent_tree
        parent.is_a?(Tree) && parent.parent_tree.nil?
      end
    end
  end

  class Tree
    #: (String annotation, ?annotate_scopes: bool, ?annotate_properties: bool) -> void
    def annotate!(annotation, annotate_scopes: false, annotate_properties: false)
      visitor = Rewriters::Annotate.new(
        annotation,
        annotate_scopes: annotate_scopes,
        annotate_properties: annotate_properties,
      )
      visitor.visit(self)
    end
  end
end

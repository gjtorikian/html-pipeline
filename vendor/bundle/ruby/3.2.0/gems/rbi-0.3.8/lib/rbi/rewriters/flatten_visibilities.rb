# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    # Flattens visibility nodes into method nodes
    #
    # Example:
    # ~~~rb
    # class A
    #   def m1; end
    #   private
    #   def m2; end
    #   def m3; end
    # end
    # ~~~
    #
    # will be transformed into:
    #
    # ~~~rb
    # class A
    #   def m1; end
    #   private def m2; end
    #   private def m3; end
    # end
    # ~~~
    class FlattenVisibilities < Visitor
      #: -> void
      def initialize
        super

        @current_visibility = [Public.new] #: Array[Visibility]
      end

      # @override
      #: (Node? node) -> void
      def visit(node)
        return unless node

        case node
        when Public, Protected, Private
          @current_visibility[-1] = node
          node.detach
        when Tree
          @current_visibility << Public.new
          visit_all(node.nodes.dup)
          @current_visibility.pop
        when Attr, Method
          node.visibility = @current_visibility.last #: as !nil
        end
      end
    end
  end

  class Tree
    #: -> void
    def flatten_visibilities!
      visitor = Rewriters::FlattenVisibilities.new
      visitor.visit(self)
    end
  end
end

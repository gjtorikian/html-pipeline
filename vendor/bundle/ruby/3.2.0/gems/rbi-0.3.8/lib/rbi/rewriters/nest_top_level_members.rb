# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    # This rewriter moves top-level members into a top-level Object class
    #
    # Example:
    # ~~~rb
    # def foo; end
    # attr_reader :bar
    # ~~~
    #
    # will be rewritten to:
    #
    # ~~~rb
    # class Object
    #  def foo; end
    #  attr_reader :bar
    # end
    # ~~~
    class NestTopLevelMembers < Visitor
      #: -> void
      def initialize
        super

        @top_level_object_class = nil #: Class?
      end

      # @override
      #: (Node? node) -> void
      def visit(node)
        return unless node

        case node
        when Tree
          visit_all(node.nodes.dup)
        else
          scope = node.parent_scope
          unless scope
            parent = node.parent_tree
            raise unless parent

            node.detach

            unless @top_level_object_class
              @top_level_object_class = Class.new("Object")
              parent.nodes << @top_level_object_class
            end

            @top_level_object_class << node
          end
        end
      end
    end
  end

  class Tree
    #: -> void
    def nest_top_level_members!
      visitor = Rewriters::NestTopLevelMembers.new
      visitor.visit(self)
    end
  end
end

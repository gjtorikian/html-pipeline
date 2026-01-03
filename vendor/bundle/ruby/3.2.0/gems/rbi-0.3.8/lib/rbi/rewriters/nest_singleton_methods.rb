# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    class NestSingletonMethods < Visitor
      # @override
      #: (Node? node) -> void
      def visit(node)
        return unless node

        case node
        when Tree
          singleton_class = SingletonClass.new

          node.nodes.dup.each do |child|
            visit(child)
            next unless child.is_a?(Method) && child.is_singleton

            child.detach
            child.is_singleton = false
            singleton_class << child
          end

          node << singleton_class unless singleton_class.empty?
        end
      end
    end
  end

  class Tree
    #: -> void
    def nest_singleton_methods!
      visitor = Rewriters::NestSingletonMethods.new
      visitor.visit(self)
    end
  end
end

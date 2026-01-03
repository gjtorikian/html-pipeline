# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    # Rewrite non-singleton methods inside singleton classes to singleton methods
    #
    # Example:
    # ~~~rb
    # class << self
    #  def m1; end
    #  def self.m2; end
    #
    #  class << self
    #    def m3; end
    #  end
    # end
    # ~~~
    #
    # will be rewritten to:
    #
    # ~~~rb
    # def self.m1; end
    #
    # class << self
    #   def self.m2; end
    #   def self.m3; end
    # end
    # ~~~
    class FlattenSingletonMethods < Visitor
      # @override
      #: (Node? node) -> void
      def visit(node)
        return unless node

        case node
        when SingletonClass
          node.nodes.dup.each do |child|
            visit(child)
            next unless child.is_a?(Method) && !child.is_singleton

            child.detach
            child.is_singleton = true
            parent_tree = node.parent_tree #: as !nil
            parent_tree << child
          end

          node.detach if node.nodes.empty?
        when Tree
          visit_all(node.nodes)
        end
      end
    end
  end

  class Tree
    #: -> void
    def flatten_singleton_methods!
      visitor = Rewriters::FlattenSingletonMethods.new
      visitor.visit(self)
    end
  end
end

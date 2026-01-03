# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class NamespaceVisitor < Visitor
      extend T::Helpers

      abstract!

      #: -> void
      def initialize
        super()

        @names_nesting = [] #: Array[String]
      end

      # @override
      #: (Prism::Node? node) -> void
      def visit(node)
        case node
        when Prism::ClassNode, Prism::ModuleNode
          constant_path = node.constant_path.slice

          if constant_path.start_with?("::")
            full_name = constant_path.delete_prefix("::")

            # We found a top level definition such as `class ::A; end`, we need to reset the name nesting
            old_nesting = @names_nesting.dup
            @names_nesting.clear
            @names_nesting << full_name

            super

            # Restore the name nesting once we finished visited the class
            @names_nesting.clear
            @names_nesting = old_nesting
          else
            @names_nesting << constant_path

            super

            @names_nesting.pop
          end
        else
          super
        end
      end
    end
  end
end

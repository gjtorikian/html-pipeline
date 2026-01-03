# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    # Visit a file to collect all the references to constants and methods
    class ReferencesVisitor < Visitor
      #: Array[Reference]
      attr_reader :references

      #: (String file) -> void
      def initialize(file)
        super()

        @file = file
        @references = [] #: Array[Reference]
      end

      # @override
      #: (Prism::AliasMethodNode node) -> void
      def visit_alias_method_node(node)
        reference_method(node.old_name.slice, node)
      end

      # @override
      #: (Prism::AndNode node) -> void
      def visit_and_node(node)
        reference_method(node.operator_loc.slice, node)
        super
      end

      # @override
      #: (Prism::BlockArgumentNode node) -> void
      def visit_block_argument_node(node)
        expression = node.expression
        case expression
        when Prism::SymbolNode
          reference_method(expression.unescaped, expression)
        else
          visit(expression)
        end
      end

      # @override
      #: (Prism::CallAndWriteNode node) -> void
      def visit_call_and_write_node(node)
        visit(node.receiver)
        reference_method(node.read_name.to_s, node)
        reference_method(node.write_name.to_s, node)
        visit(node.value)
      end

      # @override
      #: (Prism::CallOperatorWriteNode node) -> void
      def visit_call_operator_write_node(node)
        visit(node.receiver)
        reference_method(node.read_name.to_s, node)
        reference_method(node.write_name.to_s, node)
        visit(node.value)
      end

      # @override
      #: (Prism::CallOrWriteNode node) -> void
      def visit_call_or_write_node(node)
        visit(node.receiver)
        reference_method(node.read_name.to_s, node)
        reference_method(node.write_name.to_s, node)
        visit(node.value)
      end

      # @override
      #: (Prism::CallNode node) -> void
      def visit_call_node(node)
        visit(node.receiver)

        name = node.name.to_s
        reference_method(name, node)

        case name
        when "<", ">", "<=", ">="
          # For comparison operators, we also reference the `<=>` method
          reference_method("<=>", node)
        end

        visit(node.arguments)
        visit(node.block)
      end

      # @override
      #: (Prism::ClassNode node) -> void
      def visit_class_node(node)
        visit(node.superclass) if node.superclass
        visit(node.body)
      end

      # @override
      #: (Prism::ConstantAndWriteNode node) -> void
      def visit_constant_and_write_node(node)
        reference_constant(node.name.to_s, node)
        visit(node.value)
      end

      # @override
      #: (Prism::ConstantOperatorWriteNode node) -> void
      def visit_constant_operator_write_node(node)
        reference_constant(node.name.to_s, node)
        visit(node.value)
      end

      # @override
      #: (Prism::ConstantOrWriteNode node) -> void
      def visit_constant_or_write_node(node)
        reference_constant(node.name.to_s, node)
        visit(node.value)
      end

      # @override
      #: (Prism::ConstantPathNode node) -> void
      def visit_constant_path_node(node)
        visit(node.parent)
        reference_constant(node.name.to_s, node)
      end

      # @override
      #: (Prism::ConstantPathWriteNode node) -> void
      def visit_constant_path_write_node(node)
        visit(node.target.parent)
        visit(node.value)
      end

      # @override
      #: (Prism::ConstantReadNode node) -> void
      def visit_constant_read_node(node)
        reference_constant(node.name.to_s, node)
      end

      # @override
      #: (Prism::ConstantWriteNode node) -> void
      def visit_constant_write_node(node)
        visit(node.value)
      end

      # @override
      #: (Prism::LocalVariableAndWriteNode node) -> void
      def visit_local_variable_and_write_node(node)
        name = node.name.to_s
        reference_method(name, node)
        reference_method("#{name}=", node)
        visit(node.value)
      end

      # @override
      #: (Prism::LocalVariableOperatorWriteNode node) -> void
      def visit_local_variable_operator_write_node(node)
        name = node.name.to_s
        reference_method(name, node)
        reference_method("#{name}=", node)
        visit(node.value)
      end

      # @override
      #: (Prism::LocalVariableOrWriteNode node) -> void
      def visit_local_variable_or_write_node(node)
        name = node.name.to_s
        reference_method(name, node)
        reference_method("#{name}=", node)
        visit(node.value)
      end

      # @override
      #: (Prism::LocalVariableWriteNode node) -> void
      def visit_local_variable_write_node(node)
        reference_method("#{node.name}=", node)
        visit(node.value)
      end

      # @override
      #: (Prism::ModuleNode node) -> void
      def visit_module_node(node)
        visit(node.body)
      end

      # @override
      #: (Prism::MultiWriteNode node) -> void
      def visit_multi_write_node(node)
        node.lefts.each do |const|
          case const
          when Prism::LocalVariableTargetNode
            reference_method("#{const.name}=", node)
          end
        end
        visit(node.value)
      end

      # @override
      #: (Prism::OrNode node) -> void
      def visit_or_node(node)
        reference_method(node.operator_loc.slice, node)
        super
      end

      private

      #: (String name, Prism::Node node) -> void
      def reference_constant(name, node)
        @references << Reference.constant(name, node_location(node))
      end

      #: (String name, Prism::Node node) -> void
      def reference_method(name, node)
        @references << Reference.method(name, node_location(node))
      end

      #: (Prism::Node node) -> Location
      def node_location(node)
        Location.from_prism(@file, node.location)
      end
    end
  end
end

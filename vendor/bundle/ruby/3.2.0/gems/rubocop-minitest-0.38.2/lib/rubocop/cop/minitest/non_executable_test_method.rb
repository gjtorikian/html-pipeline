# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Checks for the use of test methods outside of a test class.
      #
      # Test methods should be defined within a test class to ensure their execution.
      #
      # NOTE: This cop assumes that classes whose superclass name includes the word
      # "`Test`" are test classes, in order to prevent false positives.
      #
      # @example
      #
      #   # bad
      #   class FooTest < Minitest::Test
      #   end
      #   def test_method_should_be_inside_test_class
      #   end
      #
      #   # good
      #   class FooTest < Minitest::Test
      #     def test_method_should_be_inside_test_class
      #     end
      #   end
      #
      class NonExecutableTestMethod < Base
        include MinitestExplorationHelpers

        MSG = 'Test method should be defined inside a test class to ensure execution.'

        def on_def(node)
          return if !test_method?(node) || !use_test_class?
          return if node.left_siblings.none? { |sibling| possible_test_class?(sibling) }

          add_offense(node)
        end

        private

        def use_test_class?
          root_node = processed_source.ast

          root_node.each_descendant(:class).any? { |class_node| test_class?(class_node) }
        end

        def possible_test_class?(node)
          node.is_a?(AST::ClassNode) && test_class?(node) && node.parent_class.source.include?('Test')
        end
      end
    end
  end
end

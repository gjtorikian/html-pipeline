# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # If a Minitest class inherits from another class,
      # it will also inherit its methods causing Minitest to run the parent's tests methods twice.
      #
      # This cop detects when there are two tests classes, one inherits from the other, and both have tests methods.
      # This cop will add an offense to the Child class in such a case.
      #
      # @example
      #   # bad
      #   class ParentTest < Minitest::Test
      #     def test_parent # it will run this test twice.
      #     end
      #   end
      #
      #   class ChildTest < ParentTest
      #     def test_child
      #     end
      #   end
      #
      #
      #   # good
      #   class ParentTest < Minitest::Test
      #     def test_parent
      #     end
      #   end
      #
      #   class ChildTest < Minitest::Test
      #     def test_child
      #     end
      #   end
      #
      #   # good
      #   class ParentTest < Minitest::Test
      #   end
      #
      #   class ChildTest
      #     def test_child
      #     end
      #
      #     def test_parent
      #     end
      #   end
      #
      class DuplicateTestRun < Base
        include MinitestExplorationHelpers

        MSG = "Subclasses with test methods causes the parent' tests to run them twice."

        def on_class(class_node)
          return unless test_class?(class_node)
          return unless test_methods?(class_node)
          return unless parent_class_has_test_methods?(class_node)

          add_offense(class_node)
        end

        private

        def parent_class_has_test_methods?(class_node)
          parent_class = class_node.parent_class

          return false unless (class_node_parent = class_node.parent)

          parent_class_node = class_node_parent.each_child_node(:class).detect do |klass|
            klass.identifier == parent_class
          end

          return false unless parent_class_node

          test_methods?(parent_class_node)
        end

        def test_methods?(class_node)
          test_cases(class_node).size.positive?
        end
      end
    end
  end
end

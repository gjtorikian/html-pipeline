# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Checks if test cases contain too many assertion calls. If conditional code with assertions
      # is used, the branch with maximum assertions is counted.
      # The maximum allowed assertion calls is configurable.
      #
      # @example Max: 1
      #   # bad
      #   class FooTest < Minitest::Test
      #     def test_asserts_twice
      #       assert_equal(42, do_something)
      #       assert_empty(array)
      #     end
      #   end
      #
      #   # good
      #   class FooTest < Minitest::Test
      #     def test_asserts_once
      #       assert_equal(42, do_something)
      #     end
      #
      #     def test_another_asserts_once
      #       assert_empty(array)
      #     end
      #   end
      #
      class MultipleAssertions < Base
        include MinitestExplorationHelpers

        MSG = 'Test case has too many assertions [%<total>d/%<max>d].'

        exclude_limit 'Max'

        def on_class(class_node)
          return unless test_class?(class_node)

          test_cases(class_node).each do |node|
            assertions_count = assertions_count(node.body)

            next unless assertions_count > max_assertions

            self.max = assertions_count

            message = format(MSG, total: assertions_count, max: max_assertions)
            add_offense(node, message: message)
          end
        end

        private

        def assertions_count(node)
          return 0 unless node.is_a?(RuboCop::AST::Node)

          assertions = assertions_count_based_on_type(node)
          assertions += 1 if assertion_method?(node)
          assertions
        end

        def assertions_count_based_on_type(node)
          case node.type
          when :if, :case, :case_match
            assertions_count_in_branches(node.branches)
          when :rescue
            assertions_count(node.body) + assertions_count_in_branches(node.branches)
          when :block, :numblock, :itblock
            assertions_count(node.body)
          when *RuboCop::AST::Node::ASSIGNMENTS
            assertions_count_in_assignment(node)
          else
            node.each_child_node.sum { |child| assertions_count(child) }
          end
        end

        def assertions_count_in_assignment(node)
          unless node.masgn_type?
            return 0 unless node.expression # for-style loop

            return assertions_count_based_on_type(node.expression)
          end

          rhs = node.children.last

          case rhs.type
          when :array
            rhs.children.sum { |child| assertions_count_based_on_type(child) }
          when :send
            assertion_method?(rhs) ? 1 : 0
          else
            # Play it safe and bail if we don't have any explicit handling for whatever
            # the RHS type is, since at this point we're already probably dealing with
            # a pretty exotic situation that's unlikely in the real world.
            0
          end
        end

        def assertions_count_in_branches(branches)
          branches.map { |branch| assertions_count(branch) }.max
        end

        def max_assertions
          Integer(cop_config.fetch('Max', 3))
        end
      end
    end
  end
end

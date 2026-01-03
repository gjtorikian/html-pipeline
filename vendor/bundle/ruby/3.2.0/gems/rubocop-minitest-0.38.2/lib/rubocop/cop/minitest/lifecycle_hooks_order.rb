# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Checks that lifecycle hooks are declared in the order in which they will be executed.
      #
      # @example
      #   # bad
      #   class FooTest < Minitest::Test
      #     def teardown; end
      #     def setup; end
      #   end
      #
      #   # good
      #   class FooTest < Minitest::Test
      #     def setup; end
      #     def teardown; end
      #   end
      #
      #   # bad (after test cases)
      #   class FooTest < Minitest::Test
      #     def test_something
      #       assert foo
      #     end
      #     def setup; end
      #     def teardown; end
      #   end
      #
      #   # good
      #   class FooTest < Minitest::Test
      #     def setup; end
      #     def teardown; end
      #     def test_something
      #       assert foo
      #     end
      #   end
      #
      #   # good (after non test case methods)
      #   class FooTest < Minitest::Test
      #     def do_something; end
      #     def setup; end
      #     def teardown; end
      #   end
      #
      class LifecycleHooksOrder < Base
        include MinitestExplorationHelpers
        include RangeHelp
        extend AutoCorrector

        MSG = '`%<current>s` is supposed to appear before `%<previous>s`.'

        # Regular method's position should be last.
        REGULAR_METHOD_POSITION = LIFECYCLE_HOOK_METHODS_IN_ORDER.size + 1
        HOOKS_ORDER_MAP = Hash.new do |hash, hook|
          hash[hook] = LIFECYCLE_HOOK_METHODS_IN_ORDER.index(hook) || REGULAR_METHOD_POSITION
        end

        # rubocop:disable Metrics/MethodLength
        def on_class(class_node)
          return unless test_class?(class_node)

          previous_index = -1
          previous_hook_node = nil

          hooks_and_test_cases(class_node).each do |node|
            hook = node.method_name
            index = HOOKS_ORDER_MAP[hook]

            if index < previous_index
              message = format(MSG, current: hook, previous: previous_hook_node.method_name)
              add_offense(node, message: message) do |corrector|
                autocorrect(corrector, previous_hook_node, node)
              end
            end
            previous_index = index
            previous_hook_node = node
          end
        end
        # rubocop:enable Metrics/MethodLength

        private

        def hooks_and_test_cases(class_node)
          class_def_nodes(class_node).select do |node|
            lifecycle_hook_method?(node) || test_case?(node)
          end
        end

        def autocorrect(corrector, previous_node, node)
          previous_node_range = range_with_comments_and_lines(previous_node)
          node_range = range_with_comments_and_lines(node)

          corrector.insert_before(previous_node_range, node_range.source)
          corrector.remove(node_range)
        end
      end
    end
  end
end

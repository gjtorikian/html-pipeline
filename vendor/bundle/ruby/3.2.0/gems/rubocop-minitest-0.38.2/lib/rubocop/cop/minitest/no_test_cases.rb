# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Checks if test class contains any test cases.
      #
      # @example
      #   # bad
      #   class FooTest < Minitest::Test
      #     def do_something
      #     end
      #   end
      #
      #   # good
      #   class FooTest < Minitest::Test
      #     def test_something
      #       assert true
      #     end
      #   end
      #
      class NoTestCases < Base
        include MinitestExplorationHelpers

        MSG = 'Test class should have test cases.'

        def on_class(node)
          return unless test_class?(node)

          add_offense(node) if test_cases(node).empty?
        end
      end
    end
  end
end

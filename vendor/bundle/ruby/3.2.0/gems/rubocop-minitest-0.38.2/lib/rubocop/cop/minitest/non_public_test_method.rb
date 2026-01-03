# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Detects non `public` (marked as `private` or `protected`) test methods.
      # Minitest runs only test methods which are `public`.
      #
      # @example
      #   # bad
      #   class FooTest
      #     private # or protected
      #     def test_does_something
      #       assert_equal 42, do_something
      #     end
      #   end
      #
      #   # good
      #   class FooTest
      #     def test_does_something
      #       assert_equal 42, do_something
      #     end
      #   end
      #
      #   # good (not a test case name)
      #   class FooTest
      #     private # or protected
      #     def does_something
      #       assert_equal 42, do_something
      #     end
      #   end
      #
      #   # good (no assertions)
      #   class FooTest
      #     private # or protected
      #     def test_does_something
      #       do_something
      #     end
      #   end
      #
      class NonPublicTestMethod < Base
        include MinitestExplorationHelpers
        include DefNode

        MSG = 'Non `public` test method detected. Make it `public` for it to run.'

        def on_class(node)
          test_cases(node, visibility_check: false).each do |test_case|
            add_offense(test_case) if non_public?(test_case) && assertions(test_case).any?
          end
        end
      end
    end
  end
end

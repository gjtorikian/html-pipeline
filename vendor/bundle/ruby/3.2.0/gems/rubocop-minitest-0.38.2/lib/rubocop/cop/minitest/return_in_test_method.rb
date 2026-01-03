# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the use of `skip` instead of `return` in test methods.
      #
      # @example
      #   # bad
      #   def test_something
      #     return if condition?
      #     assert_equal(42, something)
      #   end
      #
      #   # good
      #   def test_something
      #     skip if condition?
      #     assert_equal(42, something)
      #   end
      #
      class ReturnInTestMethod < Base
        include MinitestExplorationHelpers
        extend AutoCorrector

        MSG = 'Use `skip` instead of `return`.'

        def on_return(node)
          return unless node.ancestors.any? { |parent| test_case?(parent) }
          return if inside_block?(node)

          add_offense(node) do |corrector|
            corrector.replace(node, 'skip')
          end
        end

        private

        def inside_block?(node)
          node.ancestors.any?(&:any_block_type?)
        end
      end
    end
  end
end

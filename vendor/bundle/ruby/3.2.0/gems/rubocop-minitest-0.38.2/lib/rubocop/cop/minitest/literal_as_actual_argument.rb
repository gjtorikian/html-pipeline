# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces correct order of expected and
      # actual arguments for `assert_equal`.
      #
      # @example
      #   # bad
      #   assert_equal foo, 2
      #   assert_equal foo, [1, 2]
      #   assert_equal foo, [1, 2], 'message'
      #
      #   # good
      #   assert_equal 2, foo
      #   assert_equal [1, 2], foo
      #   assert_equal [1, 2], foo, 'message'
      #
      class LiteralAsActualArgument < Base
        include ArgumentRangeHelper
        extend AutoCorrector

        MSG = 'Replace the literal with the first argument.'
        RESTRICT_ON_SEND = %i[assert_equal].freeze

        def on_send(node)
          return unless node.method?(:assert_equal)

          expected, actual, _message = *node.arguments
          return unless actual&.recursive_basic_literal?
          return if expected.recursive_basic_literal?

          add_offense(all_arguments_range(node)) do |corrector|
            autocorrect(corrector, node, expected, actual)
          end
        end

        private

        def autocorrect(corrector, node, expected, actual)
          new_actual_source = if actual.hash_type? && !actual.braces?
                                "{#{actual.source}}"
                              else
                                actual.source
                              end

          corrector.replace(expected, new_actual_source)
          corrector.replace(actual, expected.source)

          wrap_with_parentheses(corrector, node) if !node.parenthesized? && actual.hash_type?
        end

        def wrap_with_parentheses(corrector, node)
          range = node.loc.selector.end.join(node.first_argument.source_range.begin)

          corrector.replace(range, '(')
          corrector.insert_after(node, ')')
        end
      end
    end
  end
end

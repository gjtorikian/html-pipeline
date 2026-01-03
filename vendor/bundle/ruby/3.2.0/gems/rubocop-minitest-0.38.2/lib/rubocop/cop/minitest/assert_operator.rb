# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the use of `assert_operator(expected, :<, actual)` over `assert(expected < actual)`.
      #
      # @example
      #
      #   # bad
      #   assert(expected < actual)
      #
      #   # good
      #   assert_operator(expected, :<, actual)
      #
      class AssertOperator < Base
        extend AutoCorrector

        MSG = 'Prefer using `assert_operator(%<new_arguments>s)`.'
        RESTRICT_ON_SEND = %i[assert].freeze
        ALLOWED_OPERATORS = [:[]].freeze

        def on_send(node)
          first_argument = node.first_argument
          return unless first_argument.respond_to?(:binary_operation?) && first_argument.binary_operation?

          operator = first_argument.to_a[1]
          return if ALLOWED_OPERATORS.include?(operator)

          new_arguments = build_new_arguments(node)

          add_offense(node, message: format(MSG, new_arguments: new_arguments)) do |corrector|
            corrector.replace(node.loc.selector, 'assert_operator')

            corrector.replace(range_of_arguments(node), new_arguments)
          end
        end

        private

        def build_new_arguments(node)
          lhs, op, rhs = *node.first_argument
          new_arguments = +"#{lhs.source}, :#{op}, #{rhs.source}"

          if node.arguments.count == 2
            new_arguments << ", #{node.last_argument.source}"
          else
            new_arguments
          end
        end

        def range_of_arguments(node)
          node.first_argument.source_range.begin.join(node.last_argument.source_range.end)
        end
      end
    end
  end
end

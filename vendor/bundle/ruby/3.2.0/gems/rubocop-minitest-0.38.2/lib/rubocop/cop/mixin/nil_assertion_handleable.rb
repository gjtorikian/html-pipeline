# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Common functionality for `AssertNil` and `RefuteNil` cops.
      # @api private
      module NilAssertionHandleable
        MSG = 'Prefer using `%<assertion_type>s_nil(%<preferred_args>s)`.'

        private

        def register_offense(node, actual, message)
          message = build_message(node, actual, message)

          add_offense(node, message: message) do |corrector|
            autocorrect(corrector, node, actual)
          end
        end

        def build_message(node, actual, message)
          message = message.first
          message_source = message&.source

          preferred_args = [actual.source, message_source].compact

          format(
            MSG,
            assertion_type: assertion_type,
            preferred_args: preferred_args.join(', '),
            method: node.method_name
          )
        end

        def autocorrect(corrector, node, actual)
          corrector.replace(node.loc.selector, :"#{assertion_type}_nil")
          if comparison_or_predicate_assertion_method?(node)
            corrector.replace(first_and_second_arguments_range(node), actual.source)
          else
            corrector.remove(node.first_argument.loc.dot)
            corrector.remove(node.first_argument.loc.selector)
          end
        end

        def comparison_or_predicate_assertion_method?(node)
          node.method?(:"#{assertion_type}_equal") || node.method?(:"#{assertion_type}_predicate")
        end
      end
    end
  end
end

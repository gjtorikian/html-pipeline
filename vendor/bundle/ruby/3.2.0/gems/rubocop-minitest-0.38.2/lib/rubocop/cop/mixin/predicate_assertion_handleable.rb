# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Common functionality for `Minitest/AssertPredicate` and `Minitest/RefutePredicate` cops.
      # @api private
      module PredicateAssertionHandleable
        MSG = 'Prefer using `%<assertion_type>s_predicate(%<new_arguments>s)`.'

        def on_send(node)
          return if node.first_argument&.any_block_type?
          return unless predicate_method?(node.first_argument)
          return unless node.first_argument.arguments.none?

          add_offense(node, message: offense_message(node.arguments)) do |corrector|
            autocorrect(corrector, node, node.arguments)
          end
        end

        def autocorrect(corrector, node, arguments)
          corrector.replace(node.loc.selector, "#{assertion_type}_predicate")

          new_arguments = new_arguments(arguments).join(', ')

          corrector.replace(node.first_argument, new_arguments)
        end

        private

        def predicate_method?(first_argument)
          first_argument.respond_to?(:predicate_method?) && first_argument.predicate_method?
        end

        def offense_message(arguments)
          message_argument = arguments.last if arguments.first != arguments.last

          new_arguments = [new_arguments(arguments), message_argument&.source].flatten.compact.join(', ')

          format(MSG, assertion_type: assertion_type, new_arguments: new_arguments)
        end

        def new_arguments(arguments)
          receiver = correct_receiver(arguments.first.receiver)
          method_name = arguments.first.method_name

          [receiver, ":#{method_name}"]
        end

        def correct_receiver(receiver)
          receiver ? receiver.source : 'self'
        end
      end
    end
  end
end

# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Tries to detect when a user accidentally used
      # `assert` when they meant to use `assert_equal`.
      #
      # NOTE: The second argument to the `assert` method named `message` and `msg` is allowed.
      #       Because their names are inferred as message arguments.
      #
      # @safety
      #   This cop is unsafe because it is not possible to determine
      #   whether the second argument of `assert` is a message or not.
      #
      # @example
      #   # bad
      #   assert(3, my_list.length)
      #   assert(expected, actual)
      #
      #   # good
      #   assert_equal(3, my_list.length)
      #   assert_equal(expected, actual)
      #   assert(foo, 'message')
      #   assert(foo, message)
      #   assert(foo, msg)
      #
      class AssertWithExpectedArgument < Base
        MSG = 'Did you mean to use `assert_equal(%<arguments>s)`?'
        RESTRICT_ON_SEND = %i[assert].freeze
        MESSAGE_VARIABLES = %w[message msg].freeze

        def_node_matcher :assert_with_two_arguments?, <<~PATTERN
          (send nil? :assert $_ $_)
        PATTERN

        def on_send(node)
          assert_with_two_arguments?(node) do |_expected, message|
            return if message.type?(:str, :dstr) || MESSAGE_VARIABLES.include?(message.source)

            arguments = node.arguments.map(&:source).join(', ')
            add_offense(node, message: format(MSG, arguments: arguments))
          end
        end
      end
    end
  end
end

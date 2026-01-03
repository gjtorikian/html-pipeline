# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the test to use `assert_empty` instead of using `assert(object.empty?)`.
      #
      # @example
      #   # bad
      #   assert(object.empty?)
      #   assert(object.empty?, 'message')
      #
      #   # good
      #   assert_empty(object)
      #   assert_empty(object, 'message')
      #
      class AssertEmpty < Base
        extend MinitestCopRule

        define_rule :assert, target_method: :empty?

        remove_method :on_send
        def on_send(node)
          return unless node.method?(:assert)
          return unless node.first_argument.respond_to?(:method?) && node.first_argument.method?(:empty?)
          return unless node.first_argument.arguments.empty?

          add_offense(node, message: offense_message(node.arguments)) do |corrector|
            autocorrect(corrector, node, node.arguments)
          end
        end
      end
    end
  end
end

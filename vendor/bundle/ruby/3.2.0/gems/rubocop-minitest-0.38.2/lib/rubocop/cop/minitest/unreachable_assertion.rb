# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Checks for `assert_raises` has an assertion method at
      # the bottom of block because the assertion will be never reached.
      #
      # @example
      #
      #   # bad
      #   assert_raises FooError do
      #     obj.occur_error
      #     assert_equal('foo', obj.bar) # Never asserted.
      #   end
      #
      #   # good
      #   assert_raises FooError do
      #     obj.occur_error
      #   end
      #   assert_equal('foo', obj.bar)
      #
      class UnreachableAssertion < Base
        include MinitestExplorationHelpers

        MSG = 'Unreachable `%<assertion_method>s` detected.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless node.method?(:assert_raises) && (body = node.body)

          last_node = body.begin_type? ? body.children.last : body
          return unless last_node.send_type?
          return if !assertion_method?(last_node) || !body.begin_type?

          add_offense(last_node, message: format(MSG, assertion_method: last_node.method_name))
        end
      end
    end
  end
end

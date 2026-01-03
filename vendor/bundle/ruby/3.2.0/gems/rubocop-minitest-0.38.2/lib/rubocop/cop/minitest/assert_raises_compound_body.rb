# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the block body of `assert_raises { ... }` to be reduced to only the raising code.
      #
      # @example
      #   # bad
      #   assert_raises(MyError) do
      #     foo
      #     bar
      #   end
      #
      #   # good
      #   assert_raises(MyError) do
      #     foo
      #   end
      #
      #   # good
      #   assert_raises(MyError) do
      #     foo do
      #       bar
      #       baz
      #     end
      #   end
      #
      class AssertRaisesCompoundBody < Base
        MSG = 'Reduce `assert_raises` block body to contain only the raising code.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless node.method?(:assert_raises) && multi_statement_begin?(node.body)

          add_offense(node)
        end

        private

        def multi_statement_begin?(node)
          node&.begin_type? && node.children.size > 1
        end
      end
    end
  end
end

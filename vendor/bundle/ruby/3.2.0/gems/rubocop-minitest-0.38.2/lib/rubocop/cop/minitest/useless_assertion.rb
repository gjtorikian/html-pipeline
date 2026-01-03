# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Detects useless assertions (assertions that either always pass or always fail).
      #
      # @example
      #   # bad
      #   assert true
      #   assert_equal @foo, @foo
      #   assert_nil [foo, bar]
      #
      #   # good
      #   assert something
      #   assert_equal foo, bar
      #   assert_nil foo
      #   assert false, "My message"
      #
      class UselessAssertion < Base
        MSG = 'Useless assertion detected.'

        SINGLE_ASSERTION_ARGUMENT_METHODS = %i[
          assert refute assert_nil refute_nil assert_not assert_empty refute_empty
        ].freeze
        TWO_ASSERTION_ARGUMENTS_METHODS = %i[
          assert_equal refute_equal assert_in_delta refute_in_delta
          assert_in_epsilon refute_in_epsilon assert_same refute_same
        ].freeze

        RESTRICT_ON_SEND = SINGLE_ASSERTION_ARGUMENT_METHODS +
                           TWO_ASSERTION_ARGUMENTS_METHODS +
                           %i[assert_includes refute_includes assert_silent]

        def on_send(node)
          return if node.receiver

          add_offense(node) if offense?(node)
        end

        private

        # rubocop:disable Metrics
        def offense?(node)
          expected, actual, = node.arguments

          case node.method_name
          when *SINGLE_ASSERTION_ARGUMENT_METHODS
            actual.nil? && expected&.literal? && !expected.xstr_type?
          when *TWO_ASSERTION_ARGUMENTS_METHODS
            return false unless expected && actual
            return false if expected.source != actual.source

            (expected.variable? && actual.variable?) ||
              (empty_composite?(expected) && empty_composite?(actual))
          when :assert_includes, :refute_includes
            expected && empty_composite?(expected)
          when :assert_silent
            block_node = node.parent
            block_node&.body.nil?
          else
            false
          end
        end
        # rubocop:enable Metrics

        def empty_composite?(node)
          return true if node.str_type? && node.value.empty?

          node.type?(:array, :hash) && node.children.empty?
        end
      end
    end
  end
end

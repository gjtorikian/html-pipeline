# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the test to use `assert_nil` instead of using
      # `assert_equal(nil, something)`, `assert(something.nil?)`, or `assert_predicate(something, :nil?)`.
      #
      # @example
      #   # bad
      #   assert_equal(nil, actual)
      #   assert_equal(nil, actual, 'message')
      #   assert(object.nil?)
      #   assert(object.nil?, 'message')
      #   assert_predicate(object, :nil?)
      #   assert_predicate(object, :nil?, 'message')
      #
      #   # good
      #   assert_nil(actual)
      #   assert_nil(actual, 'message')
      #
      class AssertNil < Base
        include ArgumentRangeHelper
        include NilAssertionHandleable
        extend AutoCorrector

        ASSERTION_TYPE = 'assert'
        RESTRICT_ON_SEND = %i[assert assert_equal assert_predicate].freeze

        def_node_matcher :nil_assertion, <<~PATTERN
          {
            (send nil? :assert_equal nil $_ $...)
            (send nil? :assert (send $_ :nil?) $...)
            (send nil? :assert_predicate $_ (sym :nil?) $...)
          }
        PATTERN

        def on_send(node)
          nil_assertion(node) do |actual, message|
            register_offense(node, actual, message)
          end
        end

        private

        def assertion_type
          ASSERTION_TYPE
        end
      end
    end
  end
end

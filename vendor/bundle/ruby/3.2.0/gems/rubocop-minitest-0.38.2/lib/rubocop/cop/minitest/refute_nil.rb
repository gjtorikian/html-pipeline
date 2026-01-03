# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the test to use `refute_nil` instead of using
      # `refute_equal(nil, something)`, `refute(something.nil?)`, or `refute_predicate(something, :nil?)`.
      #
      # @example
      #   # bad
      #   refute_equal(nil, actual)
      #   refute_equal(nil, actual, 'message')
      #   refute(actual.nil?)
      #   refute(actual.nil?, 'message')
      #   refute_predicate(object, :nil?)
      #   refute_predicate(object, :nil?, 'message')
      #
      #   # good
      #   refute_nil(actual)
      #   refute_nil(actual, 'message')
      #
      class RefuteNil < Base
        include ArgumentRangeHelper
        include NilAssertionHandleable
        extend AutoCorrector

        ASSERTION_TYPE = 'refute'
        RESTRICT_ON_SEND = %i[refute refute_equal refute_predicate].freeze

        def_node_matcher :nil_refutation, <<~PATTERN
          {
            (send nil? :refute_equal nil $_ $...)
            (send nil? :refute (send $_ :nil?) $...)
            (send nil? :refute_predicate $_ (sym :nil?) $...)
          }
        PATTERN

        def on_send(node)
          nil_refutation(node) do |actual, message|
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

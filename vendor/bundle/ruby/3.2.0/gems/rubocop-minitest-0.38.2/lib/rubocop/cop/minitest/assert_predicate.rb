# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the test to use `assert_predicate`
      # instead of using `assert(obj.a_predicate_method?)`.
      #
      # @example
      #   # bad
      #   assert(obj.one?)
      #   assert(obj.one?, 'message')
      #
      #   # good
      #   assert_predicate(obj, :one?)
      #   assert_predicate(obj, :one?, 'message')
      #
      class AssertPredicate < Base
        include ArgumentRangeHelper
        include PredicateAssertionHandleable
        extend AutoCorrector

        MSG = 'Prefer using `assert_predicate(%<new_arguments>s)`.'
        RESTRICT_ON_SEND = %i[assert].freeze # rubocop:disable InternalAffairs/UselessRestrictOnSend

        private

        def assertion_type
          'assert'
        end
      end
    end
  end
end

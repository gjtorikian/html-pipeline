# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the test to use `refute_predicate`
      # instead of using `refute(obj.a_predicate_method?)`.
      #
      # @example
      #   # bad
      #   refute(obj.one?)
      #   refute(obj.one?, 'message')
      #
      #   # good
      #   refute_predicate(obj, :one?)
      #   refute_predicate(obj, :one?, 'message')
      #
      class RefutePredicate < Base
        include ArgumentRangeHelper
        include PredicateAssertionHandleable
        extend AutoCorrector

        MSG = 'Prefer using `refute_predicate(%<new_arguments>s)`.'
        RESTRICT_ON_SEND = %i[refute].freeze # rubocop:disable InternalAffairs/UselessRestrictOnSend

        private

        def assertion_type
          'refute'
        end
      end
    end
  end
end

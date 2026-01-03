# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Checks for `assert_raises` with arguments of regular expression literals.
      # Arguments should be exception classes.
      # Optionally the last argument can be a custom message string to help explain failures.
      # Either way, it's not the argument that `exception.message` is compared to.
      # The raised exception is returned and can be used
      # to match against a regular expression.
      #
      # @example
      #
      #   # bad
      #   assert_raises FooError, /some message/ do
      #     obj.occur_error
      #   end
      #
      #   # good
      #   exception = assert_raises FooError do
      #     obj.occur_error
      #   end
      #   assert_match(/some message/, exception.message)
      #
      class AssertRaisesWithRegexpArgument < Base
        MSG = 'Do not pass regular expression literals to `assert_raises`. Test the resulting exception.'
        RESTRICT_ON_SEND = %i[assert_raises].freeze

        def on_send(node)
          add_offense(node) if node.last_argument&.regexp_type?
        end
      end
    end
  end
end

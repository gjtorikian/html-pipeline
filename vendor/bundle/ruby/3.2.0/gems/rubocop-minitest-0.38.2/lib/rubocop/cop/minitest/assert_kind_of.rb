# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the test to use `assert_kind_of(Class, object)`
      # over `assert(object.kind_of?(Class))`.
      #
      # @example
      #   # bad
      #   assert(object.kind_of?(Class))
      #   assert(object.kind_of?(Class), 'message')
      #
      #   # bad
      #   # `is_a?` is an alias for `kind_of?`
      #   assert(object.is_a?(Class))
      #   assert(object.is_a?(Class), 'message')
      #
      #   # good
      #   assert_kind_of(Class, object)
      #   assert_kind_of(Class, object, 'message')
      #
      class AssertKindOf < Base
        extend MinitestCopRule

        define_rule :assert, target_method: %i[kind_of? is_a?], preferred_method: :assert_kind_of, inverse: true
      end
    end
  end
end

# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the use of `refute_kind_of(Class, object)`
      # over `refute(object.kind_of?(Class))`.
      #
      # @example
      #   # bad
      #   refute(object.kind_of?(Class))
      #   refute(object.kind_of?(Class), 'message')
      #
      #   # bad
      #   # `is_a?` is an alias for `kind_of?`
      #   refute(object.is_of?(Class))
      #   refute(object.is_of?(Class), 'message')
      #
      #   # good
      #   refute_kind_of(Class, object)
      #   refute_kind_of(Class, object, 'message')
      #
      class RefuteKindOf < Base
        extend MinitestCopRule

        define_rule :refute, target_method: %i[kind_of? is_a?], preferred_method: :refute_kind_of, inverse: true
      end
    end
  end
end

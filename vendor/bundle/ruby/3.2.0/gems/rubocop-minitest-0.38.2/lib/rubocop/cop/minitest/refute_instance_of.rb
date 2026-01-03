# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the use of `refute_instance_of(Class, object)`
      # over `refute(object.instance_of?(Class))`.
      #
      # @example
      #   # bad
      #   refute(object.instance_of?(Class))
      #   refute(object.instance_of?(Class), 'message')
      #
      #   # bad
      #   refute_equal(Class, object.class)
      #   refute_equal(Class, object.class, 'message')
      #
      #   # good
      #   refute_instance_of(Class, object)
      #   refute_instance_of(Class, object, 'message')
      #
      class RefuteInstanceOf < Base
        include InstanceOfAssertionHandleable
        extend AutoCorrector

        RESTRICT_ON_SEND = %i[refute refute_equal].freeze

        def_node_matcher :instance_of_assertion?, <<~PATTERN
          {
            (send nil? :refute (send $_ :instance_of? $const) $_?)
            (send nil? :refute_equal $const (send $_ :class) $_?)
          }
        PATTERN

        def on_send(node)
          investigate(node, :refute)
        end
      end
    end
  end
end

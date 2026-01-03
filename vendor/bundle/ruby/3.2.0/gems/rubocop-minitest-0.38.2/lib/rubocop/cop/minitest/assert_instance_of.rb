# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the test to use `assert_instance_of(Class, object)`
      # over `assert(object.instance_of?(Class))`.
      #
      # @example
      #   # bad
      #   assert(object.instance_of?(Class))
      #   assert(object.instance_of?(Class), 'message')
      #
      #   # bad
      #   assert_equal(Class, object.class)
      #   assert_equal(Class, object.class, 'message')
      #
      #   # good
      #   assert_instance_of(Class, object)
      #   assert_instance_of(Class, object, 'message')
      #
      class AssertInstanceOf < Base
        include InstanceOfAssertionHandleable
        extend AutoCorrector

        RESTRICT_ON_SEND = %i[assert assert_equal].freeze

        def_node_matcher :instance_of_assertion?, <<~PATTERN
          {
            (send nil? :assert (send $_ :instance_of? $const) $_?)
            (send nil? :assert_equal $const (send $_ :class) $_?)
          }
        PATTERN

        def on_send(node)
          investigate(node, :assert)
        end
      end
    end
  end
end

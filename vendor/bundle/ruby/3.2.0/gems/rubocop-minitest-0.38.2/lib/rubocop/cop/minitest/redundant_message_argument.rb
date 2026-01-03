# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Detects redundant message argument in assertion methods.
      # The message argument `nil` is redundant because it is the default value.
      #
      # @example
      #
      #   # bad
      #   assert_equal(expected, actual, nil)
      #
      #   # good
      #   assert_equal(expected, actual)
      #   assert_equal(expected, actual, 'message')
      #
      class RedundantMessageArgument < Base
        extend AutoCorrector

        MSG = 'Remove the redundant message argument.'

        RESTRICT_ON_SEND = %i[
          assert assert_empty assert_equal assert_same assert_in_delta assert_in_epsilon assert_includes
          assert_instance_of assert_kind_of assert_match assert_nil assert_operator assert_path_exists
          assert_predicate assert_respond_to assert_same assert_throws
          flunk
          refute refute_empty refute_equal refute_in_delta refute_in_epsilon refute_includes
          refute_instance_of refute_kind_of refute_match refute_nil refute_operator refute_path_exists
          refute_predicate refute_respond_to refute_same
        ].freeze

        # @!method bad_method?(node)
        def_node_matcher :redundant_message_argument, <<~PATTERN
          {
            (send nil? :assert _ $nil)
            (send nil? :assert_empty _ $nil)
            (send nil? :assert_equal _ _ $nil)
            (send nil? :assert_in_delta _ _ _ $nil)
            (send nil? :assert_in_epsilon _ _ _ $nil)
            (send nil? :assert_includes _ _ $nil)
            (send nil? :assert_instance_of _ _ $nil)
            (send nil? :assert_kind_of _ _ $nil)
            (send nil? :assert_match _ _ $nil)
            (send nil? :assert_nil _ $nil)
            (send nil? :assert_operator _ _ _ $nil)
            (send nil? :assert_path_exists _ $nil)
            (send nil? :assert_predicate _ _ $nil)
            (send nil? :assert_respond_to _ _ $nil)
            (send nil? :assert_same _ _ $nil)
            (send nil? :assert_throws _ $nil)
            (send nil? :flunk $nil)
            (send nil? :refute _ $nil)
            (send nil? :refute_empty _ $nil)
            (send nil? :refute_equal _ _ $nil)
            (send nil? :refute_in_delta _ _ _ $nil)
            (send nil? :refute_in_epsilon _ _ _ $nil)
            (send nil? :refute_includes _ _ $nil)
            (send nil? :refute_instance_of _ _ $nil)
            (send nil? :refute_kind_of _ _ $nil)
            (send nil? :refute_match _ _ $nil)
            (send nil? :refute_nil _ $nil)
            (send nil? :refute_operator _ _ _ $nil)
            (send nil? :refute_path_exists _ $nil)
            (send nil? :refute_predicate _ _ $nil)
            (send nil? :refute_respond_to _ _ $nil)
            (send nil? :refute_same _ _ $nil)
          }
        PATTERN

        def on_send(node)
          return unless (redundant_message_argument = redundant_message_argument(node))

          add_offense(redundant_message_argument) do |corrector|
            if node.arguments.one?
              range = redundant_message_argument
            else
              index = node.arguments.index(redundant_message_argument)
              range = node.arguments[index - 1].source_range.end.join(redundant_message_argument.source_range.end)
            end

            corrector.remove(range)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the use of `assert_same(expected, actual)`
      # over `assert(expected.equal?(actual))`.
      #
      # NOTE: Use `assert_same` only when there is a need to compare by identity.
      #       Otherwise, use `assert_equal`.
      #
      # @example
      #   # bad
      #   assert(expected.equal?(actual))
      #   assert_equal(expected.object_id, actual.object_id)
      #
      #   # good
      #   assert_same(expected, actual)
      #
      class AssertSame < Base
        extend AutoCorrector

        MSG = 'Prefer using `assert_same(%<new_arguments>s)`.'
        RESTRICT_ON_SEND = %i[assert assert_equal].freeze

        def_node_matcher :assert_with_equal?, <<~PATTERN
          (send nil? :assert
            $(send $_ :equal? $_)
            $_?)
        PATTERN

        def_node_matcher :assert_equal_with_object_id?, <<~PATTERN
          (send nil? :assert_equal
            (send $_ :object_id)
            (send $_ :object_id)
            $_?)
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          if (equal_node, expected_node, actual_node, message_node = assert_with_equal?(node))
            add_offense(node, message: message(expected_node, actual_node, message_node.first)) do |corrector|
              corrector.replace(node.loc.selector, 'assert_same')
              corrector.replace(equal_node, "#{expected_node.source}, #{actual_node.source}")
            end
          elsif (expected_node, actual_node, message_node = assert_equal_with_object_id?(node))
            add_offense(node, message: message(expected_node, actual_node, message_node.first)) do |corrector|
              corrector.replace(node.loc.selector, 'assert_same')
              remove_method_call(expected_node.parent, corrector)
              remove_method_call(actual_node.parent, corrector)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        def message(expected_node, actual_node, message_node)
          arguments = [expected_node, actual_node, message_node].compact.map(&:source).join(', ')
          format(MSG, new_arguments: arguments)
        end

        def remove_method_call(send_node, corrector)
          range = send_node.loc.dot.join(send_node.loc.selector)
          corrector.remove(range)
        end
      end
    end
  end
end

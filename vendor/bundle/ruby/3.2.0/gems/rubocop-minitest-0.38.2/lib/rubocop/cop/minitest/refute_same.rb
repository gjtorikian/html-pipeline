# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the use of `refute_same(expected, object)`
      # over `refute(expected.equal?(actual))`.
      #
      # NOTE: Use `refute_same` only when there is a need to compare by identity.
      #       Otherwise, use `refute_equal`.
      #
      # @example
      #   # bad
      #   refute(expected.equal?(actual))
      #   refute_equal(expected.object_id, actual.object_id)
      #
      #   # good
      #   refute_same(expected, actual)
      #
      class RefuteSame < Base
        extend AutoCorrector

        MSG = 'Prefer using `refute_same(%<new_arguments>s)`.'
        RESTRICT_ON_SEND = %i[refute refute_equal].freeze

        def_node_matcher :refute_with_equal?, <<~PATTERN
          (send nil? :refute
            $(send $_ :equal? $_)
            $_?)
        PATTERN

        def_node_matcher :refute_equal_with_object_id?, <<~PATTERN
          (send nil? :refute_equal
            (send $_ :object_id)
            (send $_ :object_id)
            $_?)
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          if (equal_node, expected_node, actual_node, message_node = refute_with_equal?(node))
            add_offense(node, message: message(expected_node, actual_node, message_node.first)) do |corrector|
              corrector.replace(node.loc.selector, 'refute_same')
              corrector.replace(equal_node, "#{expected_node.source}, #{actual_node.source}")
            end
          elsif (expected_node, actual_node, message_node = refute_equal_with_object_id?(node))
            add_offense(node, message: message(expected_node, actual_node, message_node.first)) do |corrector|
              corrector.replace(node.loc.selector, 'refute_same')
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

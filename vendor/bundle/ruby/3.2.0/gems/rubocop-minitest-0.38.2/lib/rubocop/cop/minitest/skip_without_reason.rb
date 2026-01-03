# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Checks for skipped tests missing the skipping reason.
      #
      # @example
      #   # bad
      #   skip
      #   skip('')
      #
      #   # bad
      #   if condition?
      #     skip
      #   else
      #     skip
      #   end
      #
      #   # good
      #   skip("Reason why the test was skipped")
      #
      #   # good
      #   skip if condition?
      #
      class SkipWithoutReason < Base
        MSG = 'Add a reason explaining why the test is skipped.'

        RESTRICT_ON_SEND = %i[skip].freeze

        def on_send(node)
          return if node.receiver || !blank_argument?(node)

          conditional_node = conditional_parent(node)
          return if conditional_node && !only_skip_branches?(conditional_node)

          return if node.parent&.resbody_type?

          add_offense(node)
        end

        private

        def blank_argument?(node)
          message = node.first_argument
          message.nil? || (message.str_type? && message.value == '')
        end

        def conditional_parent(node)
          return unless (parent = node.parent)

          if parent.type?(:if, :case)
            parent
          elsif parent.when_type?
            parent.parent
          end
        end

        def only_skip_branches?(node)
          branches = node.branches.compact
          branches.size > 1 && branches.all? { |branch| branch.send_type? && branch.method?(:skip) }
        end
      end
    end
  end
end

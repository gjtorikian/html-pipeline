# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces tests are not focused.
      #
      # @example
      #   # bad
      #   focus test 'foo' do
      #   end
      #
      #   # bad
      #   focus
      #   test 'foo' do
      #   end
      #
      #   # good
      #   test 'foo' do
      #   end
      #
      class Focus < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Remove `focus` from tests.'
        RESTRICT_ON_SEND = [:focus].freeze

        def_node_matcher :focused?, <<~PATTERN
          (send nil? :focus ...)
        PATTERN

        def on_send(node)
          return if node.receiver

          add_offense(node.loc.selector) do |corrector|
            range = if node.arguments.none?
                      range_by_whole_lines(node.source_range, include_final_newline: true)
                    else
                      node.loc.selector.join(node.first_argument.source_range.begin)
                    end

            corrector.remove(range)
          end
        end
      end
    end
  end
end

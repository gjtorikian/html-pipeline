# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the use of `assert_equal(expected, actual)`
      # over `assert(expected == actual)`.
      #
      # @example
      #   # bad
      #   assert("rubocop-minitest" == actual)
      #   assert_operator("rubocop-minitest", :==, actual)
      #
      #   # good
      #   assert_equal("rubocop-minitest", actual)
      #
      class AssertEqual < Base
        include ArgumentRangeHelper
        extend AutoCorrector

        MSG = 'Prefer using `assert_equal(%<preferred>s)`.'
        RESTRICT_ON_SEND = %i[assert assert_operator].freeze

        def_node_matcher :assert_equal, <<~PATTERN
          {
            (send nil? :assert (send $_ :== $_) $...)
            (send nil? :assert_operator $_ (sym :==) $_ $...)
          }
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          assert_equal(node) do |expected, actual, rest_args|
            basic_arguments = "#{expected.source}, #{actual.source}"
            preferred = (message_arg = rest_args.first) ? "#{basic_arguments}, #{message_arg.source}" : basic_arguments
            message = format(MSG, preferred: preferred)

            add_offense(node, message: message) do |corrector|
              corrector.replace(node.loc.selector, 'assert_equal')

              range = if node.method?(:assert)
                        node.first_argument
                      else
                        node.first_argument.source_range.begin.join(node.arguments[2].source_range.end)
                      end

              corrector.replace(range, basic_arguments)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end

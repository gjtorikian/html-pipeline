# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the test to use `assert_match`
      # instead of using `assert(matcher.match(string))`.
      #
      # @example
      #   # bad
      #   assert(matcher.match(string))
      #   assert(matcher.match?(string))
      #   assert(matcher =~ string)
      #   assert_operator(matcher, :=~, string)
      #   assert(matcher.match(string), 'message')
      #
      #   # good
      #   assert_match(regex, string)
      #   assert_match(matcher, string, 'message')
      #
      class AssertMatch < Base
        include ArgumentRangeHelper
        extend AutoCorrector

        MSG = 'Prefer using `assert_match(%<preferred>s)`.'
        RESTRICT_ON_SEND = %i[assert assert_operator].freeze

        def_node_matcher :assert_match, <<~PATTERN
          {
            (send nil? :assert (send $_ {:match :match? :=~} $_) $...)
            (send nil? :assert_operator $_ (sym :=~) $_ $...)
          }
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          assert_match(node) do |expected, actual, rest_args|
            basic_arguments = order_expected_and_actual(expected, actual)
            preferred = (message_arg = rest_args.first) ? "#{basic_arguments}, #{message_arg.source}" : basic_arguments
            message = format(MSG, preferred: preferred)

            add_offense(node, message: message) do |corrector|
              corrector.replace(node.loc.selector, 'assert_match')

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

        private

        def order_expected_and_actual(expected, actual)
          if actual.regexp_type?
            [actual, expected]
          else
            [expected, actual]
          end.map(&:source).join(', ')
        end
      end
    end
  end
end

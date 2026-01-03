# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces the test to use `refute_match`
      # instead of using `refute(matcher.match(string))`.
      #
      # @example
      #   # bad
      #   refute(matcher.match(string))
      #   refute(matcher.match?(string))
      #   refute(matcher =~ string)
      #   refute_operator(matcher, :=~, string)
      #   assert_operator(matcher, :!~, string)
      #   refute(matcher.match(string), 'message')
      #
      #   # good
      #   refute_match(matcher, string)
      #   refute_match(matcher, string, 'message')
      #
      class RefuteMatch < Base
        include ArgumentRangeHelper
        extend AutoCorrector

        MSG = 'Prefer using `refute_match(%<preferred>s)`.'
        RESTRICT_ON_SEND = %i[refute refute_operator assert_operator].freeze

        def_node_matcher :refute_match, <<~PATTERN
          {
            (send nil? :refute (send $_ {:match :match? :=~} $_) $...)
            (send nil? :refute_operator $_ (sym :=~) $_ $...)
            (send nil? :assert_operator $_ (sym :!~) $_ $...)
          }
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          refute_match(node) do |expected, actual, rest_args|
            basic_arguments = order_expected_and_actual(expected, actual)
            preferred = (message_arg = rest_args.first) ? "#{basic_arguments}, #{message_arg.source}" : basic_arguments
            message = format(MSG, preferred: preferred)

            add_offense(node, message: message) do |corrector|
              corrector.replace(node.loc.selector, 'refute_match')

              range = if node.method?(:refute)
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

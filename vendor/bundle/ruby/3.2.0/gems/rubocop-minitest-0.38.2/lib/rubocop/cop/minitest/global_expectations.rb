# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Checks for deprecated global expectations
      # and autocorrects them to use expect format.
      #
      # @example EnforcedStyle: any (default)
      #   # bad
      #   musts.must_equal expected_musts
      #   wonts.wont_match expected_wonts
      #   musts.must_raise TypeError
      #
      #   # good
      #   _(musts).must_equal expected_musts
      #   _(wonts).wont_match expected_wonts
      #   _ { musts }.must_raise TypeError
      #
      #   expect(musts).must_equal expected_musts
      #   expect(wonts).wont_match expected_wonts
      #   expect { musts }.must_raise TypeError
      #
      #   value(musts).must_equal expected_musts
      #   value(wonts).wont_match expected_wonts
      #   value { musts }.must_raise TypeError
      #
      # @example EnforcedStyle: _
      #   # bad
      #   musts.must_equal expected_musts
      #   wonts.wont_match expected_wonts
      #   musts.must_raise TypeError
      #
      #   expect(musts).must_equal expected_musts
      #   expect(wonts).wont_match expected_wonts
      #   expect { musts }.must_raise TypeError
      #
      #   value(musts).must_equal expected_musts
      #   value(wonts).wont_match expected_wonts
      #   value { musts }.must_raise TypeError
      #
      #   # good
      #   _(musts).must_equal expected_musts
      #   _(wonts).wont_match expected_wonts
      #   _ { musts }.must_raise TypeError
      #
      # @example EnforcedStyle: expect
      #   # bad
      #   musts.must_equal expected_musts
      #   wonts.wont_match expected_wonts
      #   musts.must_raise TypeError
      #
      #   _(musts).must_equal expected_musts
      #   _(wonts).wont_match expected_wonts
      #   _ { musts }.must_raise TypeError
      #
      #   value(musts).must_equal expected_musts
      #   value(wonts).wont_match expected_wonts
      #   value { musts }.must_raise TypeError
      #
      #   # good
      #   expect(musts).must_equal expected_musts
      #   expect(wonts).wont_match expected_wonts
      #   expect { musts }.must_raise TypeError
      #
      # @example EnforcedStyle: value
      #   # bad
      #   musts.must_equal expected_musts
      #   wonts.wont_match expected_wonts
      #   musts.must_raise TypeError
      #
      #   _(musts).must_equal expected_musts
      #   _(wonts).wont_match expected_wonts
      #   _ { musts }.must_raise TypeError
      #
      #   expect(musts).must_equal expected_musts
      #   expect(wonts).wont_match expected_wonts
      #   expect { musts }.must_raise TypeError
      #
      #   # good
      #   value(musts).must_equal expected_musts
      #   value(wonts).wont_match expected_wonts
      #   value { musts }.must_raise TypeError
      class GlobalExpectations < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Use `%<preferred>s` instead.'

        VALUE_MATCHERS = MinitestExplorationHelpers::VALUE_MATCHERS
        BLOCK_MATCHERS = MinitestExplorationHelpers::BLOCK_MATCHERS

        RESTRICT_ON_SEND = MinitestExplorationHelpers::MATCHER_METHODS

        # There are aliases for the `_` method - `expect` and `value`
        DSL_METHODS = %i[_ expect value].freeze

        def on_send(node)
          receiver = node.receiver
          return unless receiver

          method = block_receiver?(receiver) || value_receiver?(receiver)
          return if method == preferred_method || (method && style == :any)

          register_offense(node, method)
        end

        private

        def_node_matcher :block_receiver?, <<~PATTERN
          (block (send nil? $#method_allowed?) _ _)
        PATTERN

        def_node_matcher :value_receiver?, <<~PATTERN
          (send nil? $#method_allowed? _)
        PATTERN

        def method_allowed?(method)
          DSL_METHODS.include?(method)
        end

        def preferred_method
          style == :any ? :_ : style
        end

        def preferred_receiver(node)
          receiver = node.receiver

          if BLOCK_MATCHERS.include?(node.method_name)
            body = receiver.lambda? ? receiver.body : receiver
            "#{preferred_method} { #{body.source} }"
          else
            "#{preferred_method}(#{receiver.source})"
          end
        end

        def register_offense(node, method)
          receiver = node.receiver

          if method
            preferred = preferred_method
            replacement = receiver.source.sub(method.to_s, preferred_method.to_s)
          else
            preferred = preferred_receiver(node)
            replacement = preferred
          end

          message = format(MSG, preferred: preferred)

          add_offense(receiver, message: message) do |corrector|
            corrector.replace(receiver, replacement)
          end
        end
      end
    end
  end
end

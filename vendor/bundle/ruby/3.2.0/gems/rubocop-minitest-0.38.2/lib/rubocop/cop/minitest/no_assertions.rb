# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Checks if test cases contain any assertion calls.
      #
      # Matchers such as `must_equal` and `wont_match` are also treated as assertion methods.
      #
      # @example
      #   # bad
      #   class FooTest < Minitest::Test
      #     def test_the_truth
      #     end
      #   end
      #
      #   # good
      #   class FooTest < Minitest::Test
      #     def test_the_truth
      #       assert true
      #     end
      #   end
      #
      #   # bad
      #   class FooTest < ActiveSupport::TestCase
      #     describe 'foo' do
      #       it 'test equal' do
      #       end
      #     end
      #   end
      #
      #   # good
      #   class FooTest < ActiveSupport::TestCase
      #     describe 'foo' do
      #       it 'test equal' do
      #         musts.must_equal expected_musts
      #       end
      #     end
      #   end
      #
      class NoAssertions < Base
        include MinitestExplorationHelpers

        MSG = 'Test case has no assertions.'

        def on_class(class_node)
          return unless test_class?(class_node)

          test_cases(class_node).each do |node|
            assertions_count = assertions_count(node)

            next if assertions_count.positive?

            add_offense(node.block_type? ? node.source_range : node.loc.name)
          end
        end
      end
    end
  end
end

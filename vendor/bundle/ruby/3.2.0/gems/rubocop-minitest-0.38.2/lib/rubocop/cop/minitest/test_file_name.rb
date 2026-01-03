# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Checks if test file names start with `test_` or end with `_test.rb`.
      # Files which define classes having names ending with `Test` are checked.
      # Not following this convention may result in tests not being run.
      #
      # @example
      #   # bad
      #   my_class.rb
      #
      #   # good
      #   my_class_test.rb
      #   test_my_class.rb
      #
      class TestFileName < Base
        include MinitestExplorationHelpers

        MSG = 'Test file path should start with `test_` or end with `_test.rb`.'

        def on_new_investigation
          return unless (ast = processed_source.ast)
          return unless test_file?(ast)

          add_global_offense(MSG) unless valid_file_name?
        end

        private

        def test_file?(node)
          return true if node.class_type? && test_class?(node)

          node.each_descendant(:class).any? { |class_node| test_class?(class_node) }
        end

        def valid_file_name?
          basename = File.basename(processed_source.file_path)

          basename.start_with?('test_') || basename.end_with?('_test.rb')
        end
      end
    end
  end
end

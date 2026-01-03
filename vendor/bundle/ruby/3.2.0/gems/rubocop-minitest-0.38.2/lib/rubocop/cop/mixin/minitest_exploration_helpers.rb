# frozen_string_literal: true

require 'set'

module RuboCop
  module Cop
    # Helper methods for different explorations against test files and test cases.
    # @api private
    module MinitestExplorationHelpers
      include DefNode
      extend NodePattern::Macros

      VALUE_MATCHERS = %i[
        must_be_empty must_equal must_be_close_to must_be_within_delta
        must_be_within_epsilon must_include must_be_instance_of must_be_kind_of
        must_match must_be_nil must_be must_respond_to must_be_same_as
        path_must_exist path_wont_exist wont_be_empty wont_equal wont_be_close_to
        wont_be_within_delta wont_be_within_epsilon wont_include wont_be_instance_of
        wont_be_kind_of wont_match wont_be_nil wont_be wont_respond_to wont_be_same_as
      ].freeze

      BLOCK_MATCHERS = %i[
        must_output must_pattern_match must_raise must_be_silent must_throw wont_pattern_match
      ].freeze

      MATCHER_METHODS = VALUE_MATCHERS + BLOCK_MATCHERS

      ASSERTION_PREFIXES = %i[assert refute].freeze

      LIFECYCLE_HOOK_METHODS_IN_ORDER = %i[
        before_setup
        setup
        after_setup
        before_teardown
        teardown
        after_teardown
      ].freeze

      LIFECYCLE_HOOK_METHODS = LIFECYCLE_HOOK_METHODS_IN_ORDER.to_set.freeze

      private

      def test_class?(class_node)
        class_node.parent_class && class_node.identifier.source.end_with?('Test')
      end

      def test_case?(node)
        return false unless (node&.def_type? && test_method?(node)) ||
                            (node&.block_type? && test_block?(node))

        class_ancestor = node.each_ancestor(:class).first
        class_ancestor && test_class?(class_ancestor)
      end

      def test_cases(class_node, visibility_check: true)
        test_methods = class_def_nodes(class_node).select do |def_node|
          test_method?(def_node, visibility_check: visibility_check)
        end

        # Support Active Support's `test 'example' { ... }` method.
        # https://api.rubyonrails.org/classes/ActiveSupport/Testing/Declarative.html
        test_blocks = class_node.each_descendant(:block).select { |block_node| test_block?(block_node) }

        test_methods + test_blocks
      end

      def test_method?(def_node, visibility_check: true)
        return false if visibility_check && non_public?(def_node)

        test_case_name?(def_node.method_name) && !def_node.arguments?
      end

      def test_block?(block_node)
        block_node.method?(:test) || block_node.method?(:it)
      end

      def lifecycle_hooks(class_node)
        class_def_nodes(class_node)
          .select { |def_node| lifecycle_hook_method?(def_node) }
      end

      def class_def_nodes(class_node)
        class_def = class_node.body
        return [] unless class_def

        if class_def.def_type?
          [class_def]
        else
          class_def.each_child_node(:def).to_a
        end
      end

      def test_case_name?(name)
        name.to_s.start_with?('test_')
      end

      def assertions(def_node)
        method_def = def_node.body
        return [] unless method_def

        send_nodes =
          if method_def.send_type?
            [method_def]
          else
            method_def.each_child_node(:send)
          end

        send_nodes.select { |send_node| assertion_method?(send_node) }
      end

      def assertions_count(node)
        node.each_descendant(:send).count do |send_node|
          assertion_method?(send_node)
        end
      end

      def assertion_method?(node)
        return false unless node
        return assertion_method?(node.expression) if node.assignment? && node.respond_to?(:expression)
        return false unless node.type?(:send, :any_block)

        assertion_prefix_method?(node) || node.method?(:flunk) || MATCHER_METHODS.include?(node.method_name)
      end

      def lifecycle_hook_method?(node)
        node.def_type? && LIFECYCLE_HOOK_METHODS.include?(node.method_name)
      end

      def assertion_prefix_method?(node)
        return false if node.receiver

        method_name = node.method_name
        ASSERTION_PREFIXES.any? { |prefix| method_name.start_with?(prefix.to_s) }
      end
    end
  end
end

# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Enforces empty line before assertion methods because it separates assertion phase.
      #
      # @example
      #
      #   # bad
      #   do_something
      #   assert_equal(expected, actual)
      #
      #   # good
      #   do_something
      #
      #   assert_equal(expected, actual)
      #
      class EmptyLineBeforeAssertionMethods < Base
        include MinitestExplorationHelpers
        include RangeHelp
        extend AutoCorrector

        MSG = 'Add empty line before assertion.'

        # rubocop:disable Metrics/CyclomaticComplexity
        def on_send(node)
          return unless (assertion_method = assertion_method(node))
          return unless (previous_line_node = assertion_method.left_sibling)
          return if node.parent.resbody_type?
          return if accept_previous_line?(previous_line_node, assertion_method)

          previous_line_node = previous_line_node.last_argument if use_heredoc_argument?(previous_line_node)
          return if use_assertion_method_at_last_of_block?(previous_line_node)
          return unless no_empty_line?(previous_line_node, assertion_method)

          register_offense(assertion_method, previous_line_node)
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        private

        def assertion_method(node)
          return node if assertion_method?(node)
          return unless (parent = node.parent)
          return unless parent.block_type?
          return if parent.method?(:test)

          node.parent if parent.body && assertion_method?(parent.body)
        end

        def accept_previous_line?(previous_line_node, node)
          return true if !previous_line_node.is_a?(RuboCop::AST::Node) ||
                         previous_line_node.args_type? || node.parent.basic_conditional?

          assertion_method?(previous_line_node)
        end

        def use_heredoc_argument?(node)
          node.respond_to?(:arguments) && heredoc?(node.last_argument)
        end

        def use_assertion_method_at_last_of_block?(node)
          return false if !node.block_type? || !node.body

          if node.body.begin_type?
            assertion_method?(node.body.children.last)
          else
            assertion_method?(node.body)
          end
        end

        def heredoc?(last_argument)
          last_argument.respond_to?(:heredoc?) && last_argument.heredoc?
        end

        def no_empty_line?(previous_line_node, node)
          previous_line = if heredoc?(previous_line_node)
                            previous_line_node.loc.heredoc_end.line
                          else
                            previous_line_node.loc.last_line
                          end

          previous_line + 1 == node.loc.line
        end

        def register_offense(node, previous_line_node)
          add_offense(node) do |corrector|
            range = if heredoc?(previous_line_node)
                      previous_line_node.loc.heredoc_end
                    else
                      range_by_whole_lines(previous_line_node.source_range, include_final_newline: true)
                    end

            corrector.insert_after(range, "\n")
          end
        end
      end
    end
  end
end

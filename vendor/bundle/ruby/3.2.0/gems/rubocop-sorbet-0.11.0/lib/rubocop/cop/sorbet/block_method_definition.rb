# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Disallow defining methods in blocks, to prevent running into issues
      # caused by https://github.com/sorbet/sorbet/issues/3609.
      #
      # As a workaround, use `define_method` instead.
      #
      # The one exception is for `Class.new` blocks, as long as the result is
      # assigned to a constant (i.e. as long as it is not an anonymous class).
      # Another exception is for ActiveSupport::Concern `class_methods` blocks.
      #
      # @example
      #   # bad
      #   yielding_method do
      #     def bad(args)
      #       # ...
      #     end
      #   end
      #
      #   # bad
      #   Class.new do
      #     def bad(args)
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   yielding_method do
      #     define_method(:good) do |args|
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   MyClass = Class.new do
      #     def good(args)
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   module SomeConcern
      #     extend ActiveSupport::Concern
      #
      #     class_methods do
      #       def good(args)
      #         # ...
      #       end
      #     end
      #   end
      #
      class BlockMethodDefinition < Base
        include RuboCop::Cop::Alignment
        extend AutoCorrector

        MSG = "Do not define methods in blocks (use `define_method` as a workaround)."

        # @!method activesupport_concern_class_methods_block?(node)
        def_node_matcher :activesupport_concern_class_methods_block?, <<~PATTERN
          (block
            (send nil? :class_methods)
            _
            _
          )
        PATTERN

        # @!method module_extends_activesupport_concern?(node)
        def_node_matcher :module_extends_activesupport_concern?, <<~PATTERN
          (module _
            (begin
              <(send nil? :extend (const (const {nil? cbase} :ActiveSupport) :Concern)) ...>
              ...
            )
          )
        PATTERN

        def on_block(node)
          if (parent = node.parent)
            return if parent.casgn_type?
          end

          # Check if this is a class_methods block inside an ActiveSupport::Concern
          return if in_activesupport_concern_class_methods_block?(node)

          node.each_descendant(:any_def) do |def_node|
            add_offense(def_node) do |corrector|
              autocorrect_method_in_block(corrector, def_node)
            end
          end
        end
        alias_method :on_numblock, :on_block

        private

        def in_activesupport_concern_class_methods_block?(node)
          return false unless activesupport_concern_class_methods_block?(node)

          immediate_module = node.each_ancestor(:module).first

          module_extends_activesupport_concern?(immediate_module)
        end

        def autocorrect_method_in_block(corrector, node)
          indent = offset(node)

          method_name = node.method_name
          args = transform_args_to_block_args(node)

          # Build the method signature replacement
          if node.def_type?
            signature_replacement = "define_method(:#{method_name}) do#{args}"
          elsif node.defs_type?
            receiver = node.receiver.source
            signature_replacement = "#{receiver}.define_singleton_method(:#{method_name}) do#{args}"
          end

          if node.body
            end_pos = node.body.source_range.begin_pos
            indentation = "\n#{indent}  "
          else
            end_pos, indentation = handle_method_without_body(node, indent)
          end

          signature_range = node.source_range.with(end_pos: end_pos)

          corrector.replace(signature_range, signature_replacement + indentation)
        end

        def transform_args_to_block_args(node)
          args = node.arguments

          if args.empty?
            ""
          else
            args_string = args.map(&:source).join(", ")
            " |#{args_string}|"
          end
        end

        def handle_method_without_body(node, indent)
          if single_line_method?(node)
            handle_single_line_method(node, indent)
          else
            handle_multiline_method_without_body(node)
          end
        end

        def single_line_method?(node)
          !node.source.include?("\n")
        end

        def handle_single_line_method(node, indent)
          end_pos = node.source_range.end_pos
          indentation = "\n#{indent}end"
          [end_pos, indentation]
        end

        def handle_multiline_method_without_body(node)
          end_pos = find_method_signature_end_position(node)
          indentation = ""
          [end_pos, indentation]
        end

        def find_method_signature_end_position(node)
          if node.arguments.any?
            find_end_position_with_arguments(node)
          else
            find_end_position_without_arguments(node)
          end
        end

        def find_end_position_with_arguments(node)
          last_arg = node.last_argument
          end_pos = last_arg.source_range.end_pos

          adjust_for_closing_parenthesis(end_pos)
        end

        def find_end_position_without_arguments(node)
          node.loc.name.end_pos
        end

        def adjust_for_closing_parenthesis(end_pos)
          source_after_last_arg = processed_source.buffer.source[end_pos..-1]

          match = closing_parenthesis_follows(source_after_last_arg)

          if match
            end_pos + match.end(0)
          else
            end_pos
          end
        end

        def closing_parenthesis_follows(source)
          source.match(/\A\s*\)/)
        end
      end
    end
  end
end

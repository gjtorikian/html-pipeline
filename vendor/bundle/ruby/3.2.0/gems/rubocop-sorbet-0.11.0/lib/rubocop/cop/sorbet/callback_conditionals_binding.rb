# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Ensures that callback conditionals are bound to the right type
      # so that they are type checked properly.
      #
      # @safety
      # Auto-correction is unsafe because other libraries define similar style callbacks as Rails, but don't always need
      # binding to the attached class. Auto-correcting those usages can lead to false positives and auto-correction
      # introduces new typing errors.
      #
      # @example
      #
      #   # bad
      #   class Post < ApplicationRecord
      #     before_create :do_it, if: -> { should_do_it? }
      #
      #     def should_do_it?
      #       true
      #     end
      #   end
      #
      #   # good
      #   class Post < ApplicationRecord
      #     before_create :do_it, if: -> {
      #       T.bind(self, Post)
      #       should_do_it?
      #     }
      #
      #     def should_do_it?
      #       true
      #     end
      #   end
      class CallbackConditionalsBinding < RuboCop::Cop::Base
        extend AutoCorrector
        include Alignment

        MSG = "Callback conditionals should be bound to the right type. Use T.bind(self, %{type})"

        RESTRICT_ON_SEND = [
          :validate,
          :validates,
          :validates_with,
          :before_validation,
          :around_validation,
          :before_create,
          :before_save,
          :before_destroy,
          :before_update,
          :after_create,
          :after_save,
          :after_destroy,
          :after_update,
          :after_touch,
          :after_initialize,
          :after_find,
          :around_create,
          :around_save,
          :around_destroy,
          :around_update,
          :before_commit,
          :after_commit,
          :after_create_commit,
          :after_destroy_commit,
          :after_rollback,
          :after_save_commit,
          :after_update_commit,
          :before_action,
          :prepend_before_action,
          :append_before_action,
          :around_action,
          :prepend_around_action,
          :append_around_action,
          :after_action,
          :prepend_after_action,
          :append_after_action,
        ].freeze

        # @!method argumentless_unbound_callable_callback_conditional?(node)
        def_node_matcher :argumentless_unbound_callable_callback_conditional?, <<~PATTERN
          (pair (sym {:if :unless})                          # callback conditional
            $(block
              (send nil? {:lambda :proc})                    # callable
              (args)                                         # argumentless
              !`(send(const {cbase nil?} :T) :bind self $_ ) # unbound
            )
          )
        PATTERN

        def on_send(node)
          type = immediately_enclosing_module_name(node)
          return unless type

          node.arguments.each do |arg|
            next unless arg.hash_type? # Skip non-keyword arguments

            arg.each_child_node do |pair_node|
              argumentless_unbound_callable_callback_conditional?(pair_node) do |block|
                add_offense(pair_node, message: format(MSG, type: type)) do |corrector|
                  block_opening_indentation = block.source_range.source_line[/\A */]
                  block_body_indentation    = block_opening_indentation + SPACE * configured_indentation_width

                  if block.single_line? # then convert to multi-line block first
                    # 1. Replace whitespace (if any) between the opening delimiter and the block body,
                    #    with newline and the correct indentation for the block body.
                    preceeding_whitespace_range = block.loc.begin.end.join(block.body.source_range.begin)
                    corrector.replace(preceeding_whitespace_range, "\n#{block_body_indentation}")

                    # 2. Replace whitespace (if any) between the block body and the closing delimiter,
                    #    with newline and the same indentation as the block opening.
                    trailing_whitespace_range = block.body.source_range.end.join(block.loc.end.begin)
                    corrector.replace(trailing_whitespace_range, "\n#{block_opening_indentation}")
                  end

                  # Prepend the binding to the block body
                  corrector.insert_before(block.body, "T.bind(self, #{type})\n#{block_body_indentation}")
                end
              end
            end
          end
        end

        private

        # Find the immediately enclosing class or module name.
        # Returns `nil`` if the immediate parent (skipping begin if present) is not a class or module.
        def immediately_enclosing_module_name(node)
          (node.parent&.begin_type? ? node.parent.parent : node.parent)&.defined_module_name
        end
      end
    end
  end
end

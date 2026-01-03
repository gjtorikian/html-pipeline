# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Forbids the use of redundant `extend T::Sig`. Only for use in
      # applications that monkey patch `Module.include(T::Sig)` globally,
      # which would make it redundant.
      #
      # @safety
      #   This cop should not be enabled in applications that have not monkey
      #   patched `Module`.
      #
      # @example
      #   # bad
      #   class Example
      #     extend T::Sig
      #     sig { void }
      #     def no_op; end
      #   end
      #
      #   # good
      #   class Example
      #     sig { void }
      #     def no_op; end
      #   end
      #
      class RedundantExtendTSig < RuboCop::Cop::Base
        include RangeHelp
        extend AutoCorrector

        MSG = "Do not redundantly `extend T::Sig` when it is already included in all modules."
        RESTRICT_ON_SEND = [:extend].freeze

        # @!method extend_t_sig?(node)
        def_node_matcher :extend_t_sig?, <<~PATTERN
          (send _ :extend (const (const {nil? | cbase} :T) :Sig))
        PATTERN

        def on_send(node)
          return unless extend_t_sig?(node)

          add_offense(node) do |corrector|
            corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))
          end
        end
      end
    end
  end
end

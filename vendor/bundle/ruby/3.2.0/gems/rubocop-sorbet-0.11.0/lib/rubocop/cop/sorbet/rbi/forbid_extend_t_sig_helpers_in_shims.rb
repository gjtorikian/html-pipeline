# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Ensures RBI shims do not include a call to extend T::Sig
      # or to extend T::Helpers
      #
      # @example
      #
      #   # bad
      #   module SomeModule
      #     extend T::Sig
      #     extend T::Helpers
      #
      #     sig { returns(String) }
      #     def foo; end
      #   end
      #
      #   # good
      #   module SomeModule
      #     sig { returns(String) }
      #     def foo; end
      #   end
      class ForbidExtendTSigHelpersInShims < RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp

        MSG = "Extending T::Sig or T::Helpers in a shim is unnecessary"
        RESTRICT_ON_SEND = [:extend].freeze

        # @!method extend_t_sig_or_helpers?(node)
        def_node_matcher :extend_t_sig_or_helpers?, <<~PATTERN
          (send nil? :extend (const (const nil? :T) {:Sig :Helpers}))
        PATTERN

        def on_send(node)
          extend_t_sig_or_helpers?(node) do
            add_offense(node) do |corrector|
              corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))
            end
          end
        end
      end
    end
  end
end

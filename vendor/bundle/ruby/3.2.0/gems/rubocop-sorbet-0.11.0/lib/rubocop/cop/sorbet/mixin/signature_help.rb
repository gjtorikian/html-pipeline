# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Mixin for writing cops for signatures, providing a `signature?` node matcher and an `on_signature` trigger.
      module SignatureHelp
        extend RuboCop::NodePattern::Macros

        # @!method signature?(node)
        def_node_matcher(:signature?, <<~PATTERN)
          {#bare_sig? #sig_with_runtime? #sig_without_runtime?}
        PATTERN

        # @!method bare_sig?(node)
        def_node_matcher(:bare_sig?, <<~PATTERN)
          (block (send
            nil?
            :sig
            (sym :final)?
          ) (args) ...)
        PATTERN

        # @!method sig_with_runtime?(node)
        def_node_matcher(:sig_with_runtime?, <<~PATTERN)
          (block (send
            (const (const {nil? cbase} :T) :Sig)
            :sig
            (sym :final)?
          ) (args) ...)
        PATTERN

        # @!method sig_without_runtime?(node)
        def_node_matcher(:sig_without_runtime?, <<~PATTERN)
          (block (send
            (const (const (const {nil? cbase} :T) :Sig) :WithoutRuntime)
            :sig
            (sym :final)?
          ) (args) ...)
        PATTERN

        def on_block(node)
          on_signature(node) if signature?(node)
        end

        alias_method :on_numblock, :on_block

        def on_signature(_node)
          # To be defined by cop class as needed
        end
      end
    end
  end
end

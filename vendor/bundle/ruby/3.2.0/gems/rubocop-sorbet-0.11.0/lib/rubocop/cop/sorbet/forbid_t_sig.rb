# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Forbids `extend T::Sig` and `include T::Sig` in classes and modules.
      #
      # This is useful when using RBS or RBS-inline syntax for type signatures,
      # where `T::Sig` is not needed and including it is redundant.
      #
      # @example
      #
      #   # bad
      #   class Example
      #     extend T::Sig
      #   end
      #
      #   # bad
      #   module Example
      #     include T::Sig
      #   end
      #
      #   # good
      #   class Example
      #   end
      class ForbidTSig < RuboCop::Cop::Base
        MSG = "Do not use `%<method>s T::Sig`."
        RESTRICT_ON_SEND = [:extend, :include].freeze

        # @!method t_sig?(node)
        def_node_matcher :t_sig?, <<~PATTERN
          (send _ {:extend :include} (const (const {nil? | cbase} :T) :Sig))
        PATTERN

        def on_send(node)
          return unless t_sig?(node)

          add_offense(node, message: format(MSG, method: node.method_name))
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end

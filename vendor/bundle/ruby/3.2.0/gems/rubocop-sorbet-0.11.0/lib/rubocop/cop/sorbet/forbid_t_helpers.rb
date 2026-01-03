# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Forbids `extend T::Helpers` and `include T::Helpers` in classes and modules.
      #
      # This is useful when using RBS or RBS-inline syntax for type signatures,
      # where `T::Helpers` is not needed and including it is redundant.
      #
      # @example
      #
      #   # bad
      #   class Example
      #     extend T::Helpers
      #   end
      #
      #   # bad
      #   module Example
      #     include T::Helpers
      #   end
      #
      #   # good
      #   class Example
      #   end
      class ForbidTHelpers < RuboCop::Cop::Base
        MSG = "Do not use `%<method>s T::Helpers`."
        RESTRICT_ON_SEND = [:extend, :include].freeze

        # @!method t_helpers?(node)
        def_node_matcher :t_helpers?, <<~PATTERN
          (send _ {:extend :include} (const (const {nil? | cbase} :T) :Helpers))
        PATTERN

        def on_send(node)
          return unless t_helpers?(node)

          add_offense(node, message: format(MSG, method: node.method_name))
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end

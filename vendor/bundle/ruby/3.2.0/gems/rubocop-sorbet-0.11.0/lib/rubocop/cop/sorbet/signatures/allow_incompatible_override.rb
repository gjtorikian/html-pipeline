# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `.override(allow_incompatible: true)`.
      # Using `allow_incompatible` suggests a violation of the Liskov
      # Substitution Principle, meaning that a subclass is not a valid
      # subtype of its superclass. This Cop prevents these design smells
      # from occurring.
      #
      # @example
      #
      #   # bad
      #   sig.override(allow_incompatible: true)
      #
      #   # good
      #   sig.override
      class AllowIncompatibleOverride < RuboCop::Cop::Base
        MSG = "Usage of `allow_incompatible` suggests a violation of the Liskov Substitution Principle. " \
          "Instead, strive to write interfaces which respect subtyping principles and remove `allow_incompatible`"
        RESTRICT_ON_SEND = [:override].freeze

        # @!method sig_dot_override?(node)
        def_node_matcher(:sig_dot_override?, <<~PATTERN)
          (send
            [!nil? #sig?]
            :override
            (hash <$(pair (sym :allow_incompatible) true) ...>)
          )
        PATTERN

        # @!method sig?(node)
        def_node_search(:sig?, <<~PATTERN)
          (send _ :sig ...)
        PATTERN

        # @!method override?(node)
        def_node_matcher(:override?, <<~PATTERN)
          (send
            _
            :override
            (hash <$(pair (sym :allow_incompatible) true) ...>)
          )
        PATTERN

        def on_send(node)
          sig_dot_override?(node) do |allow_incompatible_pair|
            add_offense(allow_incompatible_pair)
          end
        end

        def on_block(node)
          return unless sig?(node.send_node)

          block = node.children.last
          return unless block&.send_type?

          receiver = block.receiver
          while receiver
            allow_incompatible_pair = override?(receiver)
            if allow_incompatible_pair
              add_offense(allow_incompatible_pair)
              break
            end
            receiver = receiver.receiver
          end
        end

        alias_method :on_numblock, :on_block
      end
    end
  end
end

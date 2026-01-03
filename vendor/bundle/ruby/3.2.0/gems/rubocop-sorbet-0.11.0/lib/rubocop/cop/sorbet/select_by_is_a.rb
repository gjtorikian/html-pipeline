# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Suggests using `grep` over `select` when using it only for type narrowing.
      #
      # @example
      #
      #   # bad
      #   strings_or_integers.select { |e| e.is_a?(String) }
      #   strings_or_integers.filter { |e| e.is_a?(String) }
      #   strings_or_integers.select { |e| e.kind_of?(String) }
      #
      #   # good
      #   strings_or_integers.grep(String)
      class SelectByIsA < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = "Use `grep` instead of `select` when using it only for type narrowing."
        RESTRICT_ON_SEND = [:select, :filter].freeze

        # @!method type_narrowing_select?(node)
        def_node_matcher :type_narrowing_select?, <<~PATTERN
          {
            (block
              (call _ {:select :filter})
              (args (arg _))
              (send (lvar _) { :is_a? :kind_of? } (const nil? _)))
            (numblock
              (call _ {:select :filter})
              _
              (send (lvar _) { :is_a? :kind_of? } (const nil? _)))
            (itblock
              (call _ {:select :filter})
              _
              (send (lvar _) { :is_a? :kind_of? } (const nil? _)))
          }
        PATTERN

        def on_send(node)
          block_node = node.block_node

          return unless block_node
          return unless type_narrowing_select?(block_node)

          add_offense(block_node) do |corrector|
            receiver = node.receiver
            type_class = block_node.body.children[2]
            navigation = node.csend_type? ? "&." : "."
            replacement = "#{receiver.source}#{navigation}grep(#{type_class.source})"

            corrector.replace(block_node, replacement)
          end
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end

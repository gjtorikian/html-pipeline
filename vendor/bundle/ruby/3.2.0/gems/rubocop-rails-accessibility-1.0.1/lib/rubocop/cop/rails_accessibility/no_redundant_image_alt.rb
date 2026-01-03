# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module RailsAccessibility
      class NoRedundantImageAlt < Base
        MSG = "Alt prop should not contain `image` or `picture` as screen readers already announce the element as an image"
        REDUNDANT_ALT_WORDS = %w[image picture].freeze

        def_node_search :redundant_alt?, "(pair (sym :alt) (str #contains_redundant_alt_text?))"

        def on_send(node)
          receiver, method_name, = *node

          return unless receiver.nil? && method_name == :image_tag

          return unless redundant_alt?(node)

          add_offense(node.loc.selector)
        end

        private

        def contains_redundant_alt_text?(string)
          return false if string.empty?

          return true if (string.downcase.split & REDUNDANT_ALT_WORDS).any?
        end
      end
    end
  end
end

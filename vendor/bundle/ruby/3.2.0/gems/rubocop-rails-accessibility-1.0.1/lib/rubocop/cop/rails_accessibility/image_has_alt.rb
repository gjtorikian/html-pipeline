# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module RailsAccessibility
      class ImageHasAlt < Base
        MSG = "Images should have an alt prop with meaningful text or an empty string for decorative images"

        def_node_search :has_alt_attribute?, "(sym :alt)"

        def on_send(node)
          receiver, method_name, = *node

          return unless receiver.nil? && method_name == :image_tag

          alt = has_alt_attribute?(node)
          add_offense(node.loc.selector) if alt.nil?
        end
      end
    end
  end
end

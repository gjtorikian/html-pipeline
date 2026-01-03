# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module RailsAccessibility
      class NoPositiveTabindex < Base
        MSG = "Positive tabindex is error-prone and often inaccessible."

        def on_send(node)
          receiver, _method_name, *args = *node

          return unless receiver.nil?

          args_each = args.select do |arg|
            arg.type == :hash
          end
          args_each.each do |hash|
            hash.each_pair do |key, value|
              next if key.type == :dsym
              next unless key.respond_to?(:value)
              break unless key.value == :tabindex && value.source.to_i.positive?

              add_offense(hash)
            end
          end
        end
      end
    end
  end
end

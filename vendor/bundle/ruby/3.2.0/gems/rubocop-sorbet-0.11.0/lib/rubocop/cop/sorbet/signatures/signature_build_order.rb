# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks for the correct order of `sig` builder methods.
      #
      # Options:
      #
      # * `Order`: The order in which to enforce the builder methods are called.
      #
      # @example
      #   # bad
      #   sig { void.abstract }
      #
      #   # good
      #   sig { abstract.void }
      #
      #   # bad
      #   sig { returns(Integer).params(x: Integer) }
      #
      #   # good
      #   sig { params(x: Integer).returns(Integer) }
      class SignatureBuildOrder < ::RuboCop::Cop::Base
        extend AutoCorrector
        include SignatureHelp

        # @!method root_call(node)
        def_node_search(:root_call, <<~PATTERN)
          (send nil? #builder? ...)
        PATTERN

        def on_signature(node)
          body = node.body

          actual_calls_and_indexes = call_chain(body).map.with_index do |send_node, actual_index|
            # The index this method call appears at in the configured Order.
            expected_index = builder_method_indexes[send_node.method_name]

            [send_node, actual_index, expected_index]
          end

          # Temporarily extract unknown method calls
          expected_calls_and_indexes, unknown_calls_and_indexes = actual_calls_and_indexes
            .partition { |_, _, expected_index| expected_index }

          # Sort known method calls by expected index
          expected_calls_and_indexes.sort_by! { |_, _, expected_index| expected_index }

          # Re-insert unknown method calls in their positions
          unknown_calls_and_indexes.each do |entry|
            _, original_index, _ = entry

            expected_calls_and_indexes.insert(original_index, entry)
          end

          # Compare expected and actual ordering
          expected_method_names = expected_calls_and_indexes.map { |send_node, _, _| send_node.method_name }
          actual_method_names = actual_calls_and_indexes.map { |send_node, _, _| send_node.method_name }
          return if expected_method_names == actual_method_names

          add_offense(
            body,
            message: "Sig builders must be invoked in the following order: #{expected_method_names.join(", ")}.",
          ) { |corrector| corrector.replace(body, expected_source(expected_calls_and_indexes)) }
        end

        private

        def expected_source(expected_calls_and_indexes)
          expected_calls_and_indexes.reduce(nil) do |receiver_source, (send_node, _, _)|
            send_source = if send_node.arguments?
              "#{send_node.method_name}(#{send_node.arguments.map(&:source).join(", ")})"
            else
              send_node.method_name.to_s
            end

            receiver_source ? "#{receiver_source}.#{send_source}" : send_source
          end
        end

        # Split foo.bar.baz into [foo, foo.bar, foo.bar.baz]
        def call_chain(node)
          chain = []

          while node&.send_type?
            chain << node
            node = node.receiver
          end

          chain.reverse!

          chain
        end

        def builder_method_indexes
          @configured_order ||= cop_config.fetch("Order").map(&:to_sym).each_with_index.to_h.freeze
        end
      end
    end
  end
end

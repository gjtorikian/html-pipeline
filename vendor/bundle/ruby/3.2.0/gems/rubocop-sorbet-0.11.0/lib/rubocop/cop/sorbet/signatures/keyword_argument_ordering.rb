# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks for the ordering of keyword arguments required by
      # sorbet-runtime. The ordering requires that all keyword arguments
      # are at the end of the parameters list, and all keyword arguments
      # with a default value must be after those without default values.
      #
      # @example
      #
      #   # bad
      #   sig { params(a: Integer, b: String).void }
      #   def foo(a: 1, b:); end
      #
      #   # good
      #   sig { params(b: String, a: Integer).void }
      #   def foo(b:, a: 1); end
      class KeywordArgumentOrdering < ::RuboCop::Cop::Base
        include SignatureHelp

        def on_signature(node)
          method_node = node.parent.children[node.sibling_index + 1]
          return if method_node.nil?

          method_parameters = method_node.arguments

          check_order_for_kwoptargs(method_parameters)
        end

        private

        def check_order_for_kwoptargs(parameters)
          out_of_kwoptarg = false

          parameters.reverse.each do |param|
            out_of_kwoptarg = true unless param.type?(:kwoptarg, :blockarg, :kwrestarg)

            next unless param.kwoptarg_type? && out_of_kwoptarg

            add_offense(
              param,
              message: "Optional keyword arguments must be at the end of the parameter list.",
            )
          end
        end
      end
    end
  end
end

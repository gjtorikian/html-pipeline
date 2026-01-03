# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Ensure type parameters used in generic methods are always capitalized.
      #
      # @example
      #
      #   # bad
      #   sig { type_parameters(:x).params(a: T.type_parameter(:x)).void }
      #   def foo(a); end
      #
      #   # good
      #   sig { type_parameters(:X).params(a: T.type_parameter(:X)).void }
      #   def foo(a: 1); end
      class CapitalizedTypeParameters < ::RuboCop::Cop::Base
        extend AutoCorrector
        include SignatureHelp

        MSG = "Type parameters must be capitalized."

        RESTRICT_ON_SEND = [:type_parameter].freeze

        # @!method type_parameters?(node)
        def_node_matcher(:type_parameters?, <<-PATTERN)
          (send nil? :type_parameters ...)
        PATTERN

        # @!method t_type_parameter?(node)
        def_node_matcher(:t_type_parameter?, <<-PATTERN)
          (send (const {nil? | cbase} :T) :type_parameter ...)
        PATTERN

        def on_signature(node)
          send = node.children[2]

          while send&.send_type?
            if type_parameters?(send)
              check_type_parameters_case(send)
            end

            send = send.children[0]
          end
        end

        def on_send(node)
          check_type_parameters_case(node) if t_type_parameter?(node)
        end

        def on_csend(node)
          check_type_parameters_case(node) if t_type_parameter?(node)
        end

        private

        def check_type_parameters_case(node)
          node.children[2..].each do |arg|
            next unless arg.is_a?(RuboCop::AST::SymbolNode)
            next if arg.value =~ /^[A-Z]/

            add_offense(arg) do |corrector|
              corrector.replace(arg, arg.value.capitalize.to_sym.inspect)
            end
          end
        end
      end
    end
  end
end

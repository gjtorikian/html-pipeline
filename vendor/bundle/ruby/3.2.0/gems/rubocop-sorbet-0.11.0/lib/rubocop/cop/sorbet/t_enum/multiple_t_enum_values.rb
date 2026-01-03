# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Disallow creating a `T::Enum` with less than two values.
      #
      # @example
      #
      #  # bad
      #  class ErrorMessages < T::Enum
      #    enums do
      #      ServerError = new("There was a server error.")
      #    end
      #  end
      #
      #  # good
      #  class ErrorMessages < T::Enum
      #    enums do
      #      ServerError = new("There was a server error.")
      #      NotFound = new("The resource was not found.")
      #    end
      #  end
      class MultipleTEnumValues < RuboCop::Cop::Base
        include TEnum

        MSG = "`T::Enum` should have at least two values."

        # @!method enums_block?(node)
        def_node_matcher :enums_block?, <<~PATTERN
          (block (send nil? :enums) ...)
        PATTERN

        def on_class(node)
          super

          add_offense(node) if t_enum?(node) && node.body.nil?
        end

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless in_t_enum_class?
          return unless enums_block?(node)

          scope = @scopes.last

          if node.body.nil?
            add_offense(scope)
            return
          end

          begin_node = node.children.find(&:begin_type?)

          num_casgn_nodes = (begin_node || node).children.count(&:casgn_type?)
          add_offense(scope) if num_casgn_nodes < 2
        end
      end
    end
  end
end

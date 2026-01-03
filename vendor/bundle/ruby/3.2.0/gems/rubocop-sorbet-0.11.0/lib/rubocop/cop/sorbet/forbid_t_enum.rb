# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallow using `T::Enum`.
      #
      # @example
      #
      #   # bad
      #   class MyEnum < T::Enum
      #     enums do
      #       A = new
      #       B = new
      #     end
      #   end
      #
      #   # good
      #   class MyEnum
      #     A = "a"
      #     B = "b"
      #     C = "c"
      #   end
      class ForbidTEnum < RuboCop::Cop::Base
        MSG = "Using `T::Enum` is deprecated in this codebase."

        # @!method t_enum?(node)
        def_node_matcher(:t_enum?, <<~PATTERN)
          (const (const {nil? cbase} :T) :Enum)
        PATTERN

        def on_class(node)
          add_offense(node) if t_enum?(node.parent_class)
        end
      end
    end
  end
end

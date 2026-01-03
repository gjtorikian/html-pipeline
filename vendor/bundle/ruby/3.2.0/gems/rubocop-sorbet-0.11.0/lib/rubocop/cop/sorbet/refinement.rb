# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks for the use of Ruby Refinements library. Refinements add
      # complexity and incur a performance penalty that can be significant
      # for large code bases. Good examples are cases of unrelated
      # methods that happen to have the same name as these module methods.
      #
      # @example
      #   # bad
      #   module Foo
      #     refine(Date) do
      #     end
      #   end
      #
      #   # bad
      #   module Foo
      #     using(Date) do
      #     end
      #   end
      #
      #   # good
      #   module Foo
      #     bar.refine(Date)
      #   end
      #
      #   # good
      #   module Foo
      #     bar.using(Date)
      #   end

      class Refinement < Base
        MSG = "Do not use Ruby Refinements library as it is not supported by Sorbet."
        RESTRICT_ON_SEND = [:refine, :using].freeze

        def on_send(node)
          return unless node.receiver.nil?
          return unless node.first_argument&.const_type?

          if node.method?(:refine)
            return unless node.block_node
            return unless node.parent.parent.module_type?
          end

          add_offense(node)
        end
      end
    end
  end
end

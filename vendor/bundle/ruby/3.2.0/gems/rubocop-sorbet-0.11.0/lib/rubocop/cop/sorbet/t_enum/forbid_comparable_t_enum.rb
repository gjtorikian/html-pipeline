# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Disallow including the `Comparable` module in `T::Enum`.
      #
      # @example
      #
      #  # bad
      #  class Priority < T::Enum
      #    include Comparable
      #
      #    enums do
      #      High = new(3)
      #      Medium = new(2)
      #      Low = new(1)
      #    end
      #
      #    def <=>(other)
      #      serialize <=> other.serialize
      #    end
      #  end
      class ForbidComparableTEnum < RuboCop::Cop::Base
        include TEnum

        MSG = "Do not use `T::Enum` as a comparable object because of significant performance overhead."

        RESTRICT_ON_SEND = [:include, :prepend].freeze

        # @!method mix_in_comparable?(node)
        def_node_matcher :mix_in_comparable?, <<~PATTERN
          (send nil? {:include | :prepend} (const nil? :Comparable))
        PATTERN

        def on_send(node)
          return unless in_t_enum_class? && mix_in_comparable?(node)

          add_offense(node)
        end
      end
    end
  end
end

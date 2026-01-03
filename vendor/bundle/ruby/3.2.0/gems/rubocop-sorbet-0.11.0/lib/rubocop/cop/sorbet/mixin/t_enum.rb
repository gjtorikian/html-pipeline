# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Mixing for writing cops that deal with `T::Enum`s
      module TEnum
        extend RuboCop::NodePattern::Macros
        def initialize(*)
          @scopes = []
          super
        end

        # @!method t_enum?(node)
        def_node_matcher :t_enum?, <<~PATTERN
          (class (const...) (const (const nil? :T) :Enum) ...)
        PATTERN

        def on_class(node)
          @scopes.push(node)
        end

        def after_class(node)
          @scopes.pop
        end

        private

        def in_t_enum_class?
          t_enum?(@scopes&.last)
        end
      end
    end
  end
end

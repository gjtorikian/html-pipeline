# encoding: utf-8
# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows use of `T.untyped` or `T.nilable(T.untyped)`
      # as a prop type for `T::Struct` or `T::ImmutableStruct`.
      #
      # @example
      #
      #   # bad
      #   class SomeClass < T::Struct
      #     const :foo, T.untyped
      #     prop :bar, T.nilable(T.untyped)
      #   end
      #
      #   # good
      #   class SomeClass < T::Struct
      #     const :foo, Integer
      #     prop :bar, T.nilable(String)
      #   end
      class ForbidUntypedStructProps < RuboCop::Cop::Base
        MSG = "Struct props cannot be T.untyped"

        # @!method t_struct(node)
        def_node_matcher :t_struct, <<~PATTERN
          (const (const nil? :T) {:Struct :ImmutableStruct})
        PATTERN

        # @!method t_untyped(node)
        def_node_matcher :t_untyped, <<~PATTERN
          (send (const nil? :T) :untyped)
        PATTERN

        # @!method t_nilable_untyped(node)
        def_node_matcher :t_nilable_untyped, <<~PATTERN
          (send (const nil? :T) :nilable {#t_untyped #t_nilable_untyped})
        PATTERN

        # @!method subclass_of_t_struct?(node)
        def_node_matcher :subclass_of_t_struct?, <<~PATTERN
          (class (const ...) #t_struct ...)
        PATTERN

        # @!method untyped_props(node)
        # Search for untyped prop/const declarations and capture their types
        def_node_search :untyped_props, <<~PATTERN
          (send nil? {:prop :const} _ ${#t_untyped #t_nilable_untyped} ...)
        PATTERN

        def on_class(node)
          return unless subclass_of_t_struct?(node)

          untyped_props(node).each do |prop_type|
            add_offense(prop_type)
          end
        end
      end
    end
  end
end

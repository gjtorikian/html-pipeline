# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows binding the return value of `T.any`, `T.all`, `T.enum`
      # to a constant directly. To bind the value, one must use `T.type_alias`.
      #
      # @example
      #
      #   # bad
      #   FooOrBar = T.any(Foo, Bar)
      #
      #   # good
      #   FooOrBar = T.type_alias { T.any(Foo, Bar) }
      class BindingConstantWithoutTypeAlias < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = "It looks like you're trying to bind a type to a constant. " \
          "To do this, you must alias the type using `T.type_alias`."
        WITHOUT_BLOCK_MSG = "It looks like you're using the old `T.type_alias` syntax. " \
          "`T.type_alias` now expects a block." \
          'Run Sorbet with the options "--autocorrect --error-white-list=5043" ' \
          "to automatically upgrade to the new syntax."

        # @!method type_alias_without_block(node)
        def_node_matcher :type_alias_without_block, <<~PATTERN
          (send
            (const {nil? cbase} :T)
            :type_alias
            $_
          )
        PATTERN

        # @!method type_alias_with_block?(node)
        def_node_matcher :type_alias_with_block?, <<~PATTERN
          (block
            (send
              (const {nil? cbase} :T)
            :type_alias)
            ...
          )
        PATTERN

        # @!method requires_type_alias?(node)
        def_node_matcher :requires_type_alias?, <<~PATTERN
          (send
            (const {nil? cbase} :T)
            {
              :all
              :any
              :class_of
              :nilable
              :noreturn
              :proc
              :self_type
              :untyped
            }
            ...
          )
        PATTERN

        def on_casgn(node)
          expression = node.expression
          return if expression.nil? # multiple assignment

          type_alias_without_block(expression) do |type|
            return add_offense(expression, message: WITHOUT_BLOCK_MSG) do |corrector|
              corrector.replace(expression, "T.type_alias { #{type.source} }")
            end
          end

          return if type_alias_with_block?(expression)

          requires_type_alias?(send_leaf(expression)) do
            return add_offense(expression) do |corrector|
              corrector.replace(expression, "T.type_alias { #{expression.source} }")
            end
          end
        end

        private

        # Given nested send nodes, returns the leaf with explicit receiver.
        #
        # i.e. in Ruby
        #
        #     a.b.c.d.e.f
        #     ^^^
        #
        # i.e. in AST
        #
        #     (send (send (send (send (send (send nil :a) :b) :c) :d) :e) :f)
        #                             ^^^^^^^^^^^^^^^^^^^^^^^
        #
        def send_leaf(node)
          node = node.receiver while node&.receiver&.send_type?
          node
        end
      end
    end
  end
end

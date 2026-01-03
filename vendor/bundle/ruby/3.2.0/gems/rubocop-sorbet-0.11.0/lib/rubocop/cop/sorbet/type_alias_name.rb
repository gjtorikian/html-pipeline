# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Ensures all constants used as `T.type_alias` are using CamelCase.
      #
      # @example
      #
      #   # bad
      #   FOO_OR_BAR = T.type_alias { T.any(Foo, Bar) }
      #
      #   # good
      #   FooOrBar = T.type_alias { T.any(Foo, Bar) }
      class TypeAliasName < RuboCop::Cop::Base
        MSG = "Type alias constant name should be in CamelCase"

        # @!method underscored_type_alias?(node)
        def_node_matcher(:underscored_type_alias?, <<-PATTERN)
          (casgn
            _
            /_/                                  # Name matches underscore
            (block
              (send (const nil? :T) :type_alias)
              ...
            )
          )
        PATTERN

        def on_casgn(node)
          add_offense(node) if underscored_type_alias?(node)
        end
      end
    end
  end
end

# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.type_alias` anywhere.
      #
      # @example
      #
      #   # bad
      #   STRING_OR_INTEGER = T.type_alias { T.any(Integer, String) }
      #
      #   # good
      #   #: type string_or_integer = Integer | String
      class ForbidTTypeAlias < RuboCop::Cop::Base
        MSG = "Do not use `T.type_alias`."

        # @!method t_type_alias?(node)
        def_node_matcher(:t_type_alias?, "(block (call (const nil? :T) :type_alias) _ _)")

        def on_block(node)
          add_offense(node) if t_type_alias?(node)
        end
        alias_method :on_numblock, :on_block
      end
    end
  end
end

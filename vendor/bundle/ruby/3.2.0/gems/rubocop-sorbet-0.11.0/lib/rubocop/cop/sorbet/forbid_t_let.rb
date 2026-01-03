# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.let` anywhere.
      #
      # @example
      #
      #   # bad
      #   T.let(foo, Integer)
      #
      #   # good
      #   foo #: Integer
      class ForbidTLet < RuboCop::Cop::Base
        MSG = "Do not use `T.let`."
        RESTRICT_ON_SEND = [:let].freeze

        # @!method t_let?(node)
        def_node_matcher(:t_let?, "(send (const nil? :T) :let _ _)")

        def on_send(node)
          add_offense(node) if t_let?(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end

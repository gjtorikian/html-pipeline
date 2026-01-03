# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.bind` anywhere.
      #
      # @example
      #
      #   # bad
      #   T.bind(self, Integer)
      #
      #   # good
      #   #: self as Integer
      class ForbidTBind < RuboCop::Cop::Base
        MSG = "Do not use `T.bind`."
        RESTRICT_ON_SEND = [:bind].freeze

        # @!method t_bind?(node)
        def_node_matcher(:t_bind?, "(send (const nil? :T) :bind _ _)")

        def on_send(node)
          add_offense(node) if t_bind?(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end

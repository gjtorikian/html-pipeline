# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.cast` anywhere.
      #
      # @example
      #
      #   # bad
      #   T.cast(foo, Integer)
      #
      #   # good
      #   foo #: as Integer
      class ForbidTCast < RuboCop::Cop::Base
        MSG = "Do not use `T.cast`."
        RESTRICT_ON_SEND = [:cast].freeze

        # @!method t_cast?(node)
        def_node_matcher(:t_cast?, "(send (const nil? :T) :cast _ _)")

        def on_send(node)
          add_offense(node) if t_cast?(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end

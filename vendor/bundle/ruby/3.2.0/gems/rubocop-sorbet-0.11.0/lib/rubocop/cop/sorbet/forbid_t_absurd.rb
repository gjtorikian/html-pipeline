# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.absurd` anywhere.
      #
      # @example
      #
      #   # bad
      #   T.absurd(foo)
      #
      #   # good
      #   x #: absurd
      class ForbidTAbsurd < RuboCop::Cop::Base
        MSG = "Do not use `T.absurd`."
        RESTRICT_ON_SEND = [:absurd].freeze

        # @!method t_absurd?(node)
        def_node_matcher(:t_absurd?, "(send (const nil? :T) :absurd _)")

        def on_send(node)
          add_offense(node) if t_absurd?(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end

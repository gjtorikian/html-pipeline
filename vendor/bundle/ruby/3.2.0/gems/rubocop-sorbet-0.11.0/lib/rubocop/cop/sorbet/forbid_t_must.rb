# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.must` anywhere.
      #
      # @example
      #
      #   # bad
      #   T.must(foo)
      #
      #   # good
      #   foo #: as !nil
      class ForbidTMust < RuboCop::Cop::Base
        MSG = "Do not use `T.must`."
        RESTRICT_ON_SEND = [:must].freeze

        # @!method t_must?(node)
        def_node_matcher(:t_must?, "(send (const nil? :T) :must _)")

        def on_send(node)
          add_offense(node) if t_must?(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end

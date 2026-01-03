# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.untyped` anywhere.
      #
      # @example
      #
      #   # bad
      #   sig { params(my_argument: T.untyped).void }
      #   def foo(my_argument); end
      #
      #   # good
      #   sig { params(my_argument: String).void }
      #   def foo(my_argument); end
      #
      class ForbidTUntyped < RuboCop::Cop::Base
        MSG = "Do not use `T.untyped`."
        RESTRICT_ON_SEND = [:untyped].freeze

        # @!method t_untyped?(node)
        def_node_matcher(:t_untyped?, "(send (const nil? :T) :untyped)")

        def on_send(node)
          add_offense(node) if t_untyped?(node)
        end
      end
    end
  end
end

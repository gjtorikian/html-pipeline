# frozen_string_literal: true

require "stringio"

module RuboCop
  module Cop
    module Sorbet
      # Check that definitions do not use a `sig` block.
      #
      # Good:
      #
      # ```
      # #: -> void
      # def foo; end
      # ```
      #
      # Bad:
      #
      # ```
      # sig { void }
      # def foo; end
      # ```
      class ForbidSig < ::RuboCop::Cop::Base
        include SignatureHelp

        MSG = "Do not use `T::Sig`."

        def on_signature(node)
          add_offense(node) if bare_sig?(node)
        end
      end
    end
  end
end

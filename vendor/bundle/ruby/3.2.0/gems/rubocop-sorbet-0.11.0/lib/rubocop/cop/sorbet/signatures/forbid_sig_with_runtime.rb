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
      # T::Sig.sig { void }
      # def foo; end
      # ```
      class ForbidSigWithRuntime < ::RuboCop::Cop::Base
        include SignatureHelp

        MSG = "Do not use `T::Sig.sig`."

        def on_signature(node)
          add_offense(node) if sig_with_runtime?(node)
        end
      end
    end
  end
end

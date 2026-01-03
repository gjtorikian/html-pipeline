# frozen_string_literal: true

require "stringio"

module RuboCop
  module Cop
    module Sorbet
      # Check that `sig` is used instead of `T::Sig::WithoutRuntime.sig`.
      #
      # Good:
      #
      # ```
      # sig { void }
      # def foo; end
      # ```
      #
      # Bad:
      #
      # ```
      # T::Sig::WithoutRuntime.sig { void }
      # def foo; end
      # ```
      class ForbidSigWithoutRuntime < ::RuboCop::Cop::Base
        include SignatureHelp
        extend AutoCorrector

        MSG = "Do not use `T::Sig::WithoutRuntime.sig`."

        def on_signature(node)
          return unless sig_without_runtime?(node)

          sig = node.children[0]
          add_offense(sig) do |corrector|
            corrector.replace(sig, sig.source.gsub(/T\s*::\s*Sig\s*::\s*WithoutRuntime\s*\.\s*/m, ""))
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Disallows the usage of `checked(true)`. This usage could cause
      # confusion; it could lead some people to believe that a method would be checked
      # even if runtime checks have not been enabled on the class or globally.
      # Additionally, in the event where checks are enabled, `checked(true)` would
      # be redundant; only `checked(false)` or `soft` would change the behaviour.
      #
      # @example
      #
      #   # bad
      #   sig { void.checked(true) }
      #
      #   # good
      #   sig { void }
      class CheckedTrueInSignature < ::RuboCop::Cop::Base
        include(RuboCop::Cop::RangeHelp)
        include(RuboCop::Cop::Sorbet::SignatureHelp)

        # @!method offending_node(node)
        def_node_search(:offending_node, <<~PATTERN)
          (send _ :checked (true))
        PATTERN

        MESSAGE =
          "Using `checked(true)` in a method signature definition is not allowed. " \
            "`checked(true)` is the default behavior for modules/classes with runtime checks enabled. " \
            "To enable typechecking at runtime for this module, regardless of global settings, " \
            "`include(WaffleCone::RuntimeChecks)` to this module and set other methods to `checked(false)`."
        private_constant(:MESSAGE)

        def on_signature(node)
          error = offending_node(node).first
          return unless error

          add_offense(
            source_range(
              processed_source.buffer,
              error.location.line,
              (error.location.selector.begin_pos)..(error.location.end.begin_pos),
            ),
            message: MESSAGE,
          )
        end
      end
    end
  end
end

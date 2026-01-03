# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Checks for the a mistaken variant of the "obsolete memoization pattern" that used to be required
      # for older Sorbet versions in `#typed: strict` files. The mistaken variant would overwrite the ivar with `nil`
      # on every call, causing the memoized value to be discarded and recomputed on every call.
      #
      # This cop will correct it to read from the ivar instead of `nil`, which will memoize it correctly.
      #
      # The result of this correction will be the "obsolete memoization pattern", which can further be corrected by
      # the `Sorbet/ObsoleteStrictMemoization` cop.
      #
      # See `Sorbet/ObsoleteStrictMemoization` for more details.
      #
      # @safety
      #   If the computation being memoized had side effects, calling it only once (instead of once on every call
      #   to the affected method) can be observed, and might be a breaking change.
      #
      # @example
      #   # bad
      #   sig { returns(Foo) }
      #   def foo
      #     # This `nil` is likely a mistake, causing the memoized value to be discarded and recomputed on every call.
      #     @foo = T.let(nil, T.nilable(Foo))
      #     @foo ||= some_computation
      #   end
      #
      #   # good
      #   sig { returns(Foo) }
      #   def foo
      #     # This will now memoize the value as was likely intended, so `some_computation` is only ever called once.
      #     # ⚠️If `some_computation` has side effects, this might be a breaking change!
      #     @foo = T.let(@foo, T.nilable(Foo))
      #     @foo ||= some_computation
      #   end
      #
      # @see Sorbet/ObsoleteStrictMemoization
      class BuggyObsoleteStrictMemoization < RuboCop::Cop::Base
        include RuboCop::Cop::MatchRange
        include RuboCop::Cop::Alignment
        include RuboCop::Cop::LineLengthHelp
        include RuboCop::Cop::RangeHelp
        extend AutoCorrector

        include TargetSorbetVersion

        MSG = "This might be a mistaken variant of the two-stage workaround that used to be needed for memoization " \
          "in `#typed: strict` files. See https://sorbet.org/docs/type-assertions#put-type-assertions-behind-memoization."

        # @!method buggy_legacy_memoization_pattern?(node)
        def_node_matcher :buggy_legacy_memoization_pattern?, <<~PATTERN
          (begin
            ...                                                       # Ignore any other lines that come first.
            (ivasgn $_ivar                                           # First line: @_ivar = ...
              (send                                                   # T.let(_ivar, T.nilable(_ivar_type))
                (const {nil? cbase} :T) :let
                $nil
                (send (const {nil? cbase} :T) :nilable _ivar_type))) # T.nilable(_ivar_type)
            (or-asgn (ivasgn _ivar) _initialization_expr))          # Second line: @_ivar ||= _initialization_expr
        PATTERN

        def on_begin(node)
          buggy_legacy_memoization_pattern?(node) do |ivar, nil_node|
            add_offense(nil_node) do |corrector|
              corrector.replace(
                range_between(nil_node.source_range.begin_pos, nil_node.source_range.end_pos),
                ivar,
              )
            end
          end
        end

        def relevant_file?(file)
          super && sorbet_enabled?
        end
      end
    end
  end
end

# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Detect and autocorrect `T.any(..., NilClass, ...)` to `T.nilable(...)`
      #
      # @example
      #
      #   # bad
      #   T.any(String, NilClass)
      #   T.any(NilClass, String)
      #   T.any(NilClass, Symbol, String)
      #
      #   # good
      #   T.nilable(String)
      #   T.nilable(String)
      #   T.nilable(T.any(Symbol, String))
      class ForbidTAnyWithNil < Base
        extend AutoCorrector

        MSG = "Use `T.nilable` instead of `T.any(..., NilClass, ...)`."
        RESTRICT_ON_SEND = [:any].freeze

        # @!method t_any_call?(node)
        def_node_matcher :t_any_call?, <<~PATTERN
          (send (const nil? :T) :any $...)
        PATTERN

        # @!method nil_const_node?(node)
        def_node_matcher :nil_const_node?, <<~PATTERN
          (const nil? :NilClass)
        PATTERN

        def on_send(node)
          args = t_any_call?(node)
          return unless args

          nil_args, non_nil_args = args.partition { |a| nil_const_node?(a) }
          return if nil_args.empty? || non_nil_args.empty?

          add_offense(node) do |corrector|
            replacement = build_replacement(non_nil_args)

            corrector.replace(node, replacement)
          end
        end
        alias_method :on_csend, :on_send

        private

        def build_replacement(non_nil_args)
          sources = non_nil_args.map(&:source)
          inner = sources.size == 1 ? sources.first : "T.any(#{sources.join(", ")})"
          "T.nilable(#{inner})"
        end
      end
    end
  end
end

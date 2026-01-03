# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Checks for the obsolete pattern for initializing instance variables that was required for older Sorbet
      # versions in `#typed: strict` files.
      #
      # It's no longer required, as of Sorbet 0.5.10210
      # See https://sorbet.org/docs/type-assertions#put-type-assertions-behind-memoization
      #
      # @example
      #
      #   # bad
      #   sig { returns(Foo) }
      #   def foo
      #     @foo = T.let(@foo, T.nilable(Foo))
      #     @foo ||= Foo.new
      #   end
      #
      #   # bad
      #   sig { returns(Foo) }
      #   def foo
      #     # This would have been a mistake, causing the memoized value to be discarded and recomputed on every call.
      #     @foo = T.let(nil, T.nilable(Foo))
      #     @foo ||= Foo.new
      #   end
      #
      #   # good
      #   sig { returns(Foo) }
      #   def foo
      #     @foo ||= T.let(Foo.new, T.nilable(Foo))
      #   end
      #
      class ObsoleteStrictMemoization < RuboCop::Cop::Base
        include RuboCop::Cop::MatchRange
        include RuboCop::Cop::Alignment
        include RuboCop::Cop::LineLengthHelp
        include RuboCop::Cop::RangeHelp
        extend AutoCorrector

        include TargetSorbetVersion
        minimum_target_sorbet_static_version "0.5.10210"

        MSG = "This two-stage workaround for memoization in `#typed: strict` files is no longer necessary. " \
          "See https://sorbet.org/docs/type-assertions#put-type-assertions-behind-memoization."

        # @!method legacy_memoization_pattern?(node)
        def_node_matcher :legacy_memoization_pattern?, <<~PATTERN
          (begin
            ...                                                       # Ignore any other lines that come first.
            $(ivasgn $_ivar                                           # First line: @_ivar = ...
              (send                                                   # T.let(_ivar, T.nilable(_ivar_type))
                $(const {nil? cbase} :T) :let
                (ivar _ivar)
                (send (const {nil? cbase} :T) :nilable $_ivar_type))) # T.nilable(_ivar_type)
            $(or-asgn (ivasgn _ivar) $_initialization_expr))          # Second line: @_ivar ||= _initialization_expr
        PATTERN

        def on_begin(node)
          legacy_memoization_pattern?(node) do |first_asgn_node, ivar, t, ivar_type, second_or_asgn_node, init_expr| # rubocop:disable Metrics/ParameterLists
            add_offense(first_asgn_node) do |corrector|
              indent = offset(node)
              correction = "#{ivar} ||= #{t.source}.let(#{init_expr.source}, #{t.source}.nilable(#{ivar_type.source}))"

              # We know good places to put line breaks, if required.
              if line_length(indent + correction) > max_line_length || correction.include?("\n")
                correction = <<~RUBY.chomp
                  #{ivar} ||= #{t.source}.let(
                  #{indent}  #{init_expr.source.gsub("\n", "\n#{indent}")},
                  #{indent}  #{t.source}.nilable(#{ivar_type.source.gsub("\n", "\n#{indent}")}),
                  #{indent})
                RUBY
              end

              corrector.replace(
                range_between(first_asgn_node.source_range.begin_pos, second_or_asgn_node.source_range.end_pos),
                correction,
              )
            end
          end
        end

        def relevant_file?(file)
          super && enabled_for_sorbet_static_version?
        end
      end
    end
  end
end

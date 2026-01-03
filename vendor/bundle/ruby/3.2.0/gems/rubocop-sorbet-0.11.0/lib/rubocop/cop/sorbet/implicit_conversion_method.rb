# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows declaring implicit conversion methods.
      # Since Sorbet is a nominal (not structural) type system,
      # implicit conversion is currently unsupported.
      #
      # @example
      #
      #   # bad
      #   def to_str; end
      #
      #   # good
      #   def to_str(x); end
      #
      #   # bad
      #   def self.to_str; end
      #
      #   # good
      #   def self.to_str(x); end
      #
      #   # bad
      #   alias to_str to_s
      #
      # @see https://docs.ruby-lang.org/en/master/implicit_conversion_rdoc.html
      # @note Since the arity of aliased methods is not checked, false positives may result.
      class ImplicitConversionMethod < RuboCop::Cop::Base
        IMPLICIT_CONVERSION_METHODS = [:to_ary, :to_int, :to_hash, :to_str].freeze
        MSG = "Avoid implicit conversion methods, as Sorbet does not support them. " \
          "Explicity convert to the desired type instead."
        RESTRICT_ON_SEND = [:alias_method].freeze

        def on_alias(node)
          new_id = node.new_identifier
          add_offense(new_id) if IMPLICIT_CONVERSION_METHODS.include?(new_id.value)
        end

        def on_def(node)
          return unless IMPLICIT_CONVERSION_METHODS.include?(node.method_name)
          return unless node.arguments.empty?

          add_offense(node)
        end
        alias_method :on_defs, :on_def

        def on_send(node)
          add_offense(node.first_argument) if IMPLICIT_CONVERSION_METHODS.include?(node.first_argument.value)
        end
      end
    end
  end
end

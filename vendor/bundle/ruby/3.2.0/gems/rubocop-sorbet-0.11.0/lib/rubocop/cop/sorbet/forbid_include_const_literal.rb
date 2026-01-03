# encoding: utf-8
# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Correct `send` expressions in include statements by constant literals.
      #
      # Sorbet, the static checker, is not (yet) able to support constructs on the
      # following form:
      #
      # ```ruby
      # class MyClass
      #   include send_expr
      # end
      # ```
      #
      # Multiple occurences of this can be found in Shopify's code base like:
      #
      # ```ruby
      # include Rails.application.routes.url_helpers
      # ```
      # or
      # ```ruby
      # include Polaris::Engine.helpers
      # ```
      class ForbidIncludeConstLiteral < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = "`%<inclusion_method>s` must only be used with constant literals as arguments"
        RESTRICT_ON_SEND = [:include, :extend, :prepend].freeze

        # @!method dynamic_inclusion?(node)
        def_node_matcher :dynamic_inclusion?, <<~PATTERN
          (send nil? ${:include :extend :prepend} $#neither_const_nor_self?)
        PATTERN

        def on_send(node)
          dynamic_inclusion?(node) do |inclusion_method, included|
            return unless within_onymous_module?(node)

            add_offense(node, message: format(MSG, inclusion_method: inclusion_method)) do |corrector|
              corrector.replace(node, "T.unsafe(self).#{inclusion_method} #{included.source}")
            end
          end
        end

        private

        def neither_const_nor_self?(node)
          !node.type?(:const, :self)
        end

        # Returns true if the node is within a module declaration that is not anonymous.
        def within_onymous_module?(node)
          parent = node.parent
          parent = parent.parent while parent&.type?(:begin, :block)
          parent&.type?(:module, :class, :sclass)
        end
      end
    end
  end
end

# encoding: utf-8
# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Correct superclass `send` expressions by constant literals.
      #
      # Sorbet, the static checker, is not (yet) able to support constructs on the
      # following form:
      #
      # ```ruby
      # class Foo < send_expr; end
      # ```
      #
      # Multiple occurences of this can be found in Shopify's code base like:
      #
      # ```ruby
      # class ShopScope < Component::TrustedIdScope[ShopIdentity::ShopId]
      # ```
      # or
      # ```ruby
      # class ApiClientEligibility < Struct.new(:api_client, :match_results, :shop)
      # ```

      class ForbidSuperclassConstLiteral < RuboCop::Cop::Base
        MSG = "Superclasses must only contain constant literals"

        # @!method dynamic_superclass?(node)
        def_node_matcher :dynamic_superclass?, <<-PATTERN
          (class (const ...) $(send ...) ...)
        PATTERN

        def on_class(node)
          dynamic_superclass?(node) do |superclass|
            add_offense(superclass)
          end
        end
      end
    end
  end
end

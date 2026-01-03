# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class RemoveEmptyPayloadScopes < Base
        extend T::Sig

        include Runtime::Reflection

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          event.node.detach if @pipeline.symbol_in_payload?(event.symbol) && event.node.empty?
        end

        sig { override.params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end

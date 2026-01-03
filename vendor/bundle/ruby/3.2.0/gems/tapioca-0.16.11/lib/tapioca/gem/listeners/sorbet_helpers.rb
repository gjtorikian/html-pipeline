# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetHelpers < Base
        extend T::Sig

        include Runtime::Reflection

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          constant = event.constant
          node = event.node

          abstract_type = abstract_type_of(constant)

          node << RBI::Helper.new(abstract_type.to_s) if abstract_type
          node << RBI::Helper.new("final") if final_module?(constant)
          node << RBI::Helper.new("sealed") if sealed_module?(constant)
        end

        sig { override.params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end

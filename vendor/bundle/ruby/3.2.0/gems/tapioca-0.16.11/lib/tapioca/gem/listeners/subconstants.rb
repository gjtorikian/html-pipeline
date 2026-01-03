# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class Subconstants < Base
        extend T::Sig

        include Runtime::Reflection

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          symbol = event.symbol
          constant = event.constant

          prefix = symbol == "Object" ? "" : symbol

          constants_of(constant).sort.uniq.map do |constant_name|
            name = "#{prefix}::#{constant_name}"
            subconstant = constantize(name)

            # Don't compile modules of Object because Object::Foo == Foo
            # Don't compile modules of BasicObject because BasicObject::BasicObject == BasicObject
            next if (Object == constant || BasicObject == constant) && Module === subconstant
            next unless Runtime::Reflection.constant_defined?(subconstant)

            @pipeline.push_constant(name, subconstant)
          end
        end

        sig { override.params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end

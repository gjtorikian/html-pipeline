# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class ForeignConstants < Base
        extend T::Sig

        include Runtime::Reflection

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          mixin = event.constant
          return if Class === mixin # Classes can't be mixed into other constants

          # There are cases where we want to process constants not declared by the current
          # gem, i.e. "foreign constant". These are constants defined in another gem to which
          # this gem is applying a mix-in. This pattern is especially common for gems that add
          # behavior to Ruby standard library classes by mixing in modules to them.
          #
          # The way we identify these "foreign constants" is by asking the mixin tracker which
          # constants have mixed in the current module that we are handling. We add all the
          # constants that we discover to the pipeline to be processed.
          Runtime::Trackers::Mixin.constants_with_mixin(mixin).each do |mixin_type, location_info|
            location_info.each do |constant, location|
              next unless mixed_in_by_gem?(location)

              name = @pipeline.name_of(constant)

              # Calling Tapioca::Gem::Pipeline#name_of on a singleton class returns `nil`.
              # To handle this case, use string parsing to get the name of the singleton class's
              # base constant. Then, generate RBIs as if the base constant is extending the mixin,
              # which is functionally equivalent to including or prepending to the singleton class.
              if !name && constant.singleton_class?
                attached_class = Runtime::Trackers::Mixin.resolve_to_attached_class(constant, mixin, mixin_type)
                next unless attached_class

                constant = attached_class
                name = @pipeline.name_of(constant)
              end

              @pipeline.push_foreign_constant(name, constant) if name
            end
          end
        end

        sig do
          params(
            location: String,
          ).returns(T::Boolean)
        end
        def mixed_in_by_gem?(location)
          @pipeline.gem.contains_path?(location)
        end

        sig { override.params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end

# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module Mixin
        extend Tracker
        extend T::Sig

        @constants_to_mixin_locations = {}.compare_by_identity
        @mixins_to_constants = {}.compare_by_identity

        class Type < T::Enum
          enums do
            Prepend = new
            Include = new
            Extend = new
          end
        end

        class << self
          extend T::Sig

          sig do
            type_parameters(:Result)
              .params(block: T.proc.returns(T.type_parameter(:Result)))
              .returns(T.type_parameter(:Result))
          end
          def with_disabled_registration(&block)
            with_disabled_tracker(&block)
          end

          sig { params(constant: Module, mixin: Module, mixin_type: Type).void }
          def register(constant, mixin, mixin_type)
            return unless enabled?

            location = Reflection.resolve_loc(caller_locations)

            register_with_location(constant, mixin, mixin_type, location)
          end

          def resolve_to_attached_class(constant, mixin, mixin_type)
            attached_class = Reflection.attached_class_of(constant)
            return unless attached_class

            if mixin_type == Type::Include || mixin_type == Type::Prepend
              location = mixin_location(mixin, mixin_type, constant)
              register_with_location(constant, mixin, Type::Extend, T.must(location))
            end

            attached_class
          end

          sig { params(mixin: Module).returns(T::Hash[Type, T::Hash[Module, String]]) }
          def constants_with_mixin(mixin)
            find_or_initialize_mixin_lookup(mixin)
          end

          sig { params(mixin: Module, mixin_type: Type, constant: Module).returns(T.nilable(String)) }
          def mixin_location(mixin, mixin_type, constant)
            find_or_initialize_mixin_lookup(mixin).dig(mixin_type, constant)
          end

          private

          sig { params(constant: Module, mixin: Module, mixin_type: Type, location: String).void }
          def register_with_location(constant, mixin, mixin_type, location)
            return unless @enabled

            constants = find_or_initialize_mixin_lookup(mixin)
            constants.fetch(mixin_type).store(constant, location)
          end

          sig { params(mixin: Module).returns(T::Hash[Type, T::Hash[Module, String]]) }
          def find_or_initialize_mixin_lookup(mixin)
            @mixins_to_constants[mixin] ||= {
              Type::Prepend => {}.compare_by_identity,
              Type::Include => {}.compare_by_identity,
              Type::Extend => {}.compare_by_identity,
            }
          end
        end
      end
    end
  end
end

class Module
  prepend(Module.new do
    def prepend_features(constant)
      Tapioca::Runtime::Trackers::Mixin.register(
        constant,
        self,
        Tapioca::Runtime::Trackers::Mixin::Type::Prepend,
      )

      super
    end

    def append_features(constant)
      Tapioca::Runtime::Trackers::Mixin.register(
        constant,
        self,
        Tapioca::Runtime::Trackers::Mixin::Type::Include,
      )

      super
    end

    def extend_object(obj)
      Tapioca::Runtime::Trackers::Mixin.register(
        obj,
        self,
        Tapioca::Runtime::Trackers::Mixin::Type::Extend,
      ) if Module === obj
      super
    end
  end)
end

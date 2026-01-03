# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      module ActiveModelTypeHelper
        class << self
          extend T::Sig

          # Returns the type indicated by the custom ActiveModel::Type::Value.
          # Accepts subclasses of ActiveModel::Type::Value as well as classes that implement similar methods.
          sig { params(type_value: T.untyped).returns(String) }
          def type_for(type_value)
            return "T.untyped" if Runtime::GenericTypeRegistry.generic_type_instance?(type_value)

            type = lookup_tapioca_type(type_value) ||
              lookup_return_type_of_method(type_value, :deserialize) ||
              lookup_return_type_of_method(type_value, :cast) ||
              lookup_return_type_of_method(type_value, :cast_value) ||
              lookup_arg_type_of_method(type_value, :serialize) ||
              T.untyped
            type.to_s
          end

          sig { params(type_value: T.untyped).returns(T::Boolean) }
          def assume_nilable?(type_value)
            !type_value.respond_to?(:__tapioca_type)
          end

          private

          MEANINGLESS_TYPES = T.let(
            [
              T.untyped,
              T.noreturn,
              T::Private::Types::Void,
              T::Private::Types::NotTyped,
            ].freeze,
            T::Array[Object],
          )

          sig { params(type: T.untyped).returns(T::Boolean) }
          def meaningful_type?(type)
            !MEANINGLESS_TYPES.include?(type)
          end

          sig { params(obj: T.untyped).returns(T.nilable(T::Types::Base)) }
          def lookup_tapioca_type(obj)
            T::Utils.coerce(obj.__tapioca_type) if obj.respond_to?(:__tapioca_type)
          end

          sig { params(obj: T.untyped, method: Symbol).returns(T.nilable(T::Types::Base)) }
          def lookup_return_type_of_method(obj, method)
            return_type = lookup_signature_of_method(obj, method)&.return_type
            return unless return_type && meaningful_type?(return_type)

            return_type
          end

          sig { params(obj: T.untyped, method: Symbol).returns(T.nilable(T::Types::Base)) }
          def lookup_arg_type_of_method(obj, method)
            # Arg types is an array of [name, type] entries, so we dig into first entry (index 0)
            # and then into the type which is the last element (index 1)
            first_arg_type = lookup_signature_of_method(obj, method)&.arg_types&.dig(0, 1)
            return unless first_arg_type && meaningful_type?(first_arg_type)

            first_arg_type
          end

          sig { params(obj: T.untyped, method: Symbol).returns(T.untyped) }
          def lookup_signature_of_method(obj, method)
            Runtime::Reflection.signature_of(obj.method(method))
          rescue NameError
            nil
          end
        end
      end
    end
  end
end

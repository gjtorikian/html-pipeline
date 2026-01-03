# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      module GraphqlTypeHelper
        extend self

        extend T::Sig

        sig do
          params(
            argument: GraphQL::Schema::Argument,
            constant: T.any(T.class_of(GraphQL::Schema::Mutation), T.class_of(GraphQL::Schema::InputObject)),
          ).returns(String)
        end
        def type_for_argument(argument, constant)
          type = if argument.loads
            loads_type = ::GraphQL::Schema::Wrapper.new(argument.loads)
            loads_type = loads_type.to_list_type if argument.type.list?
            loads_type = loads_type.to_non_null_type if argument.type.non_null?
            loads_type
          else
            argument.type
          end

          prepare = argument.prepare
          prepare_method = if prepare.is_a?(Symbol) || prepare.is_a?(String)
            if constant.respond_to?(prepare)
              constant.method(prepare.to_sym)
            end
          end

          type_for(
            type,
            ignore_nilable_wrapper: has_replaceable_default?(argument),
            prepare_method: prepare_method,
          )
        end

        sig do
          params(
            type: T.any(
              GraphQL::Schema::Wrapper,
              T.class_of(GraphQL::Schema::Scalar),
              T.class_of(GraphQL::Schema::Enum),
              T.class_of(GraphQL::Schema::Union),
              T.class_of(GraphQL::Schema::Object),
              T.class_of(GraphQL::Schema::Interface),
              T.class_of(GraphQL::Schema::InputObject),
            ),
            ignore_nilable_wrapper: T::Boolean,
            prepare_method: T.nilable(Method),
          ).returns(String)
        end
        def type_for(type, ignore_nilable_wrapper: false, prepare_method: nil)
          unwrapped_type = type.unwrap

          parsed_type = case unwrapped_type
          when GraphQL::Types::Boolean.singleton_class
            "T::Boolean"
          when GraphQL::Types::Float.singleton_class
            type_for_constant(Float)
          when GraphQL::Types::ID.singleton_class, GraphQL::Types::String.singleton_class
            type_for_constant(String)
          when GraphQL::Types::Int.singleton_class, GraphQL::Types::BigInt.singleton_class
            type_for_constant(Integer)
          when GraphQL::Types::ISO8601Date.singleton_class
            type_for_constant(Date)
          when GraphQL::Types::ISO8601DateTime.singleton_class
            type_for_constant(Time)
          when GraphQL::Types::JSON.singleton_class
            "T::Hash[::String, T.untyped]"
          when GraphQL::Schema::Enum.singleton_class
            enum_values = T.cast(unwrapped_type.enum_values, T::Array[GraphQL::Schema::EnumValue])
            value_types = enum_values.map { |v| type_for_constant(v.value.class) }.uniq

            if value_types.size == 1
              T.must(value_types.first)
            else
              "T.any(#{value_types.join(", ")})"
            end
          when GraphQL::Schema::Scalar.singleton_class
            method = Runtime::Reflection.method_of(unwrapped_type, :coerce_input)
            signature = Runtime::Reflection.signature_of(method)
            return_type = signature&.return_type

            valid_return_type?(return_type) ? return_type.to_s : "T.untyped"
          when GraphQL::Schema::InputObject.singleton_class
            type_for_constant(unwrapped_type)
          when Module
            Runtime::Reflection.qualified_name_of(unwrapped_type) || "T.untyped"
          else
            "T.untyped"
          end

          if prepare_method
            prepare_signature = Runtime::Reflection.signature_of(prepare_method)
            prepare_return_type = prepare_signature&.return_type
            if valid_return_type?(prepare_return_type)
              parsed_type = prepare_return_type&.to_s
            end
          end

          if type.list?
            parsed_type = "T::Array[#{parsed_type}]"
          end

          unless type.non_null? || ignore_nilable_wrapper
            parsed_type = RBIHelper.as_nilable_type(parsed_type)
          end

          parsed_type
        end

        private

        sig { params(constant: Module).returns(String) }
        def type_for_constant(constant)
          if constant.instance_methods.include?(:prepare)
            prepare_method = constant.instance_method(:prepare)

            prepare_signature = Runtime::Reflection.signature_of(prepare_method)

            return prepare_signature.return_type&.to_s if valid_return_type?(prepare_signature&.return_type)
          end

          Runtime::Reflection.qualified_name_of(constant) || "T.untyped"
        end

        sig { params(argument: GraphQL::Schema::Argument).returns(T::Boolean) }
        def has_replaceable_default?(argument)
          !!argument.replace_null_with_default? && !argument.default_value.nil?
        end

        sig { params(return_type: T.nilable(T::Types::Base)).returns(T::Boolean) }
        def valid_return_type?(return_type)
          !!return_type && !(T::Private::Types::Void === return_type || T::Private::Types::NotTyped === return_type)
        end
      end
    end
  end
end

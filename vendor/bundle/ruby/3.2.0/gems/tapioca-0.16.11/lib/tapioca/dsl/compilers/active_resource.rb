# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveResource::Base)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveResource` decorates RBI files for subclasses of
      # [`ActiveResource::Base`](https://github.com/rails/activeresource) which declare
      # `schema` fields.
      #
      # For example, with the following `ActiveResource::Base` subclass:
      #
      # ~~~rb
      # class Post < ActiveResource::Base
      #   schema do
      #     integer 'id', 'month', 'year'
      #   end
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   sig { returns(Integer) }
      #   def id; end
      #
      #   sig { params(id: Integer).returns(Integer) }
      #   def id=(id); end
      #
      #   sig { returns(T::Boolean) }
      #   def id?; end
      #
      #   sig { returns(Integer) }
      #   def month; end
      #
      #   sig { params(month: Integer).returns(Integer) }
      #   def month=(month); end
      #
      #   sig { returns(T::Boolean) }
      #   def month?; end
      #
      #   sig { returns(Integer) }
      #   def year; end
      #
      #   sig { params(year: Integer).returns(Integer) }
      #   def year=(year); end
      #
      #   sig { returns(T::Boolean) }
      #   def year?; end
      # end
      # ~~~
      class ActiveResource < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ActiveResource::Base) } }

        sig { override.void }
        def decorate
          return if constant.schema.blank?

          root.create_path(constant) do |resource|
            constant.schema.each do |attribute, type|
              create_schema_methods(resource, attribute, type)
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActiveResource::Base)
          end
        end

        private

        TYPES = T.let(
          {
            boolean: "T::Boolean",
            integer: "Integer",
            string: "String",
            float: "Float",
            date: "Date",
            time: "Time",
            datetime: "DateTime",
            decimal: "BigDecimal",
            binary: "String",
            text: "String",
          }.freeze,
          T::Hash[Symbol, String],
        )

        sig { params(attr_type: Symbol).returns(String) }
        def type_for(attr_type)
          TYPES.fetch(attr_type, "T.untyped")
        end

        sig { params(klass: RBI::Scope, attribute: String, type: String).void }
        def create_schema_methods(klass, attribute, type)
          return_type = type_for(type.to_sym)

          klass.create_method(attribute, return_type: return_type)
          klass.create_method("#{attribute}?", return_type: "T::Boolean")
          klass.create_method(
            "#{attribute}=",
            parameters: [
              create_param("value", type: return_type),
            ],
            return_type: return_type,
          )
        end
      end
    end
  end
end

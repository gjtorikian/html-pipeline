# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base) && defined?(ActiveRecord::TypedStore)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordTypedStore` generates RBI files for Active Record models that use
      # [`ActiveRecord::TypedStore`](https://github.com/byroot/activerecord-typedstore) features.
      #
      # For example, with the following ActiveRecord class:
      #
      # ~~~rb
      # # post.rb
      # class Post < ApplicationRecord
      #   typed_store :metadata do |s|
      #     s.string(:reviewer, blank: false, accessor: false)
      #     s.date(:review_date)
      #     s.boolean(:reviewed, null: false, default: false)
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
      #   include StoreAccessors
      #
      #   module StoreAccessors
      #     sig { params(review_date: T.nilable(Date)).returns(T.nilable(Date)) }
      #     def review_date=(review_date); end
      #
      #     sig { returns(T.nilable(Date)) }
      #     def review_date; end
      #
      #     sig { returns(T.nilable(Date)) }
      #     def review_date_was; end
      #
      #     sig { returns(T::Boolean) }
      #     def review_date_changed?; end
      #
      #     sig { returns(T.nilable(Date)) }
      #     def review_date_before_last_save; end
      #
      #     sig { returns(T::Boolean) }
      #     def saved_change_to_review_date?; end
      #
      #     sig { returns(T.nilable([T.nilable(Date), T.nilable(Date)])) }
      #     def review_date_change; end
      #
      #     sig { returns(T.nilable([T.nilable(Date), T.nilable(Date)])) }
      #     def saved_change_to_review_date; end
      #
      #     sig { params(reviewed: T::Boolean).returns(T::Boolean) }
      #     def reviewed=(reviewed); end
      #
      #     sig { returns(T::Boolean) }
      #     def reviewed; end
      #
      #     sig { returns(T::Boolean) }
      #     def reviewed_was; end
      #
      #     sig { returns(T::Boolean) }
      #     def reviewed_changed?; end
      #
      #     sig { returns(T::Boolean) }
      #     def reviewed_before_last_save; end
      #
      #     sig { returns(T::Boolean) }
      #     def saved_change_to_reviewed?; end
      #
      #     sig { returns(T.nilable([T::Boolean, T::Boolean])) }
      #     def reviewed_change; end
      #
      #     sig { returns(T.nilable([T::Boolean, T::Boolean])) }
      #     def saved_change_to_reviewed; end
      #   end
      # end
      # ~~~
      class ActiveRecordTypedStore < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        sig { override.void }
        def decorate
          stores = constant.typed_stores
          return if stores.values.all? { |store| store.accessors.empty? }

          root.create_path(constant) do |model|
            store_accessors_module = model.create_module("StoreAccessors")
            model.create_include("StoreAccessors")

            stores.values.each do |store_data|
              store_data.accessors.each do |accessor, name|
                field = store_data.fields.fetch(accessor)
                type = type_for(field)
                name ||= field.name # support < 1.5.0

                generate_methods(store_accessors_module, name.to_s, type)
              end
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActiveRecord::Base).select do |klass|
              klass.include?(ActiveRecord::TypedStore::Behavior)
            end
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
            any: "T.untyped",
          }.freeze,
          T::Hash[Symbol, String],
        )

        sig { params(field: ActiveRecord::TypedStore::Field).returns(String) }
        def type_for(field)
          type = TYPES.fetch(field.type_sym, "T.untyped")

          type = if field.array
            # `null: false` applies to the array itself, not the elements, which are always nilable.
            # https://github.com/byroot/activerecord-typedstore/blob/2f3fb98/spec/support/models.rb#L46C34-L46C45
            # https://github.com/byroot/activerecord-typedstore/blob/2f3fb98/spec/active_record/typed_store_spec.rb#L854-L857
            nilable_element_type = as_nilable_type(type)
            "T::Array[#{nilable_element_type}]"
          else
            type
          end

          type = as_nilable_type(type) if field.null

          type
        end

        sig do
          params(
            klass: RBI::Scope,
            name: String,
            type: String,
          )
            .void
        end
        def generate_methods(klass, name, type)
          klass.create_method(
            "#{name}=",
            parameters: [create_param(name, type: type)],
            return_type: type,
          )
          klass.create_method(name, return_type: type)
          klass.create_method("#{name}?", return_type: "T::Boolean")
          klass.create_method("#{name}_was", return_type: type)
          klass.create_method("#{name}_changed?", return_type: "T::Boolean")
          klass.create_method("#{name}_before_last_save", return_type: type)
          klass.create_method("saved_change_to_#{name}?", return_type: "T::Boolean")
          klass.create_method("#{name}_change", return_type: "T.nilable([#{type}, #{type}])")
          klass.create_method("saved_change_to_#{name}", return_type: "T.nilable([#{type}, #{type}])")
        end
      end
    end
  end
end

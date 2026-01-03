# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base) && defined?(IdentityCache::WithoutPrimaryIndex)

require "tapioca/dsl/helpers/active_record_column_type_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::IdentityCache` generates RBI files for Active Record models
      #  that use `include IdentityCache`.
      # [`IdentityCache`](https://github.com/Shopify/identity_cache) is a blob level caching solution
      # to plug into Active Record.
      #
      # For example, with the following Active Record class:
      #
      # ~~~rb
      # # post.rb
      # class Post < ApplicationRecord
      #    include IdentityCache
      #
      #    cache_index :blog_id
      #    cache_index :title, unique: true
      #    cache_index :title, :review_date, unique: true
      #
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   sig { params(blog_id: T.untyped, includes: T.untyped).returns(T::Array[::Post])
      #   def fetch_by_blog_id(blog_id, includes: nil); end
      #
      #   sig { params(blog_ids: T.untyped, includes: T.untyped).returns(T::Array[::Post])
      #   def fetch_multi_by_blog_id(index_values, includes: nil); end
      #
      #   sig { params(title: T.untyped, includes: T.untyped).returns(::Post) }
      #   def fetch_by_title!(title, includes: nil); end
      #
      #   sig { params(title: T.untyped, includes: T.untyped).returns(T.nilable(::Post)) }
      #   def fetch_by_title(title, includes: nil); end
      #
      #   sig { params(index_values: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
      #   def fetch_multi_by_title(index_values, includes: nil); end
      #
      #   sig { params(title: T.untyped, review_date: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
      #   def fetch_by_title_and_review_date!(title, review_date, includes: nil); end
      #
      #   sig { params(title: T.untyped, review_date: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
      #   def fetch_by_title_and_review_date(title, review_date, includes: nil); end
      # end
      # ~~~
      class IdentityCache < Compiler
        extend T::Sig

        COLLECTION_TYPE = T.let(
          ->(type) { "T::Array[::#{type}]" },
          T.proc.params(type: T.any(Module, String)).returns(String),
        )

        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        sig { override.void }
        def decorate
          caches = constant.send(:all_cached_associations)
          cache_indexes = constant.send(:cache_indexes)
          return if caches.empty? && cache_indexes.empty?

          root.create_path(constant) do |model|
            cache_manys = constant.send(:cached_has_manys)
            cache_ones = constant.send(:cached_has_ones)
            cache_belongs = constant.send(:cached_belongs_tos)

            cache_indexes.each do |field|
              create_fetch_by_methods(field, model)
            end

            cache_manys.values.each do |field|
              create_fetch_field_methods(field, model, returns_collection: true)
            end

            cache_ones.values.each do |field|
              create_fetch_field_methods(field, model, returns_collection: false)
            end

            cache_belongs.values.each do |field|
              create_fetch_field_methods(field, model, returns_collection: false)
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActiveRecord::Base).select do |klass|
              ::IdentityCache::WithoutPrimaryIndex > klass
            end
          end
        end

        private

        sig do
          params(
            field: T.untyped,
            returns_collection: T::Boolean,
          ).returns(String)
        end
        def type_for_field(field, returns_collection:)
          cache_type = field.reflection.compute_class(field.reflection.class_name)
          if returns_collection
            COLLECTION_TYPE.call(cache_type)
          else
            as_nilable_type(T.must(qualified_name_of(cache_type)))
          end
        rescue ArgumentError
          "T.untyped"
        end

        sig do
          params(
            field: T.untyped,
            klass: RBI::Scope,
            returns_collection: T::Boolean,
          ).void
        end
        def create_fetch_field_methods(field, klass, returns_collection:)
          name = field.cached_accessor_name.to_s
          type = type_for_field(field, returns_collection: returns_collection)
          klass.create_method(name, return_type: type)

          if field.respond_to?(:cached_ids_name)
            klass.create_method(field.cached_ids_name, return_type: "T::Array[T.untyped]")
          elsif field.respond_to?(:cached_id_name)
            klass.create_method(field.cached_id_name, return_type: "T.untyped")
          end
        end

        sig do
          params(
            field: T.untyped,
            klass: RBI::Scope,
          ).void
        end
        def create_fetch_by_methods(field, klass)
          is_cache_index = field.instance_variable_defined?(:@attribute_proc)

          # Both `cache_index` and `cache_attribute` generate aliased methods
          create_aliased_fetch_by_methods(field, klass)

          # If the method used was `cache_index` a few extra methods are created
          create_index_fetch_by_methods(field, klass) if is_cache_index
        end

        sig do
          params(
            field: T.untyped,
            klass: RBI::Scope,
          ).void
        end
        def create_index_fetch_by_methods(field, klass)
          fields_name = field.key_fields.join("_and_")
          name = "fetch_by_#{fields_name}"
          parameters = field.key_fields.map do |arg|
            create_param(arg.to_s, type: "T.untyped")
          end
          parameters << create_kw_opt_param("includes", default: "nil", type: "T.untyped")

          if field.unique
            type = T.must(qualified_name_of(constant))

            klass.create_method(
              "#{name}!",
              class_method: true,
              parameters: parameters,
              return_type: type,
            )

            klass.create_method(
              name,
              class_method: true,
              parameters: parameters,
              return_type: as_nilable_type(type),
            )
          else
            klass.create_method(
              name,
              class_method: true,
              parameters: parameters,
              return_type: COLLECTION_TYPE.call(constant),
            )
          end

          klass.create_method(
            "fetch_multi_by_#{fields_name}",
            class_method: true,
            parameters: [
              create_param("index_values", type: "T::Enumerable[T.untyped]"),
              create_kw_opt_param("includes", default: "nil", type: "T.untyped"),
            ],
            return_type: COLLECTION_TYPE.call(constant),
          )
        end

        sig do
          params(
            field: T.untyped,
            klass: RBI::Scope,
          ).void
        end
        def create_aliased_fetch_by_methods(field, klass)
          type, _ = Helpers::ActiveRecordColumnTypeHelper.new(
            constant,
            column_type_option: Helpers::ActiveRecordColumnTypeHelper::ColumnTypeOption::Nilable,
          ).type_for(field.alias_name.to_s)
          multi_type = type.delete_prefix("T.nilable(").delete_suffix(")").delete_prefix("::")
          suffix = field.send(:fetch_method_suffix)

          parameters = field.key_fields.map do |arg|
            create_param(arg.to_s, type: "T.untyped")
          end

          klass.create_method(
            "fetch_#{suffix}",
            class_method: true,
            parameters: parameters,
            return_type: field.unique ? type : COLLECTION_TYPE.call(type),
          )

          klass.create_method(
            "fetch_multi_#{suffix}",
            class_method: true,
            parameters: [create_param("keys", type: "T::Enumerable[T.untyped]")],
            return_type: COLLECTION_TYPE.call(multi_type),
          )
        end
      end
    end
  end
end

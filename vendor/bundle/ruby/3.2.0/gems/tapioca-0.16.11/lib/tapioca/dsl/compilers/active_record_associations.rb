# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

require "tapioca/dsl/helpers/active_record_constants_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordAssociations` refines RBI files for subclasses of
      # [`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html).
      # This compiler is only responsible for defining the methods that would be created for the associations that
      # are defined in the Active Record model.
      #
      # For example, with the following model class:
      #
      # ~~~rb
      # class Post < ActiveRecord::Base
      #   belongs_to :category
      #   has_many :comments
      #   has_one :author, class_name: "User"
      #
      #   accepts_nested_attributes_for :category, :comments, :author
      # end
      # ~~~
      #
      # this compiler will produce the following methods in the RBI file
      # `post.rbi`:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      #
      # class Post
      #   include Post::GeneratedAssociationMethods
      #
      #   module Post::GeneratedAssociationMethods
      #     sig { returns(T.nilable(::User)) }
      #     def author; end
      #
      #     sig { params(value: T.nilable(::User)).void }
      #     def author=(value); end
      #
      #     sig { params(attributes: T.untyped).returns(T.untyped) }
      #     def author_attributes=(attributes); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
      #     def build_author(*args, &blk); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::Category) }
      #     def build_category(*args, &blk); end
      #
      #     sig { returns(T.nilable(::Category)) }
      #     def category; end
      #
      #     sig { params(value: T.nilable(::Category)).void }
      #     def category=(value); end
      #
      #     sig { params(attributes: T.untyped).returns(T.untyped) }
      #     def category_attributes=(attributes); end
      #
      #     sig { returns(T::Array[T.untyped]) }
      #     def comment_ids; end
      #
      #     sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
      #     def comment_ids=(ids); end
      #
      #     sig { returns(::ActiveRecord::Associations::CollectionProxy[::Comment]) }
      #     def comments; end
      #
      #     sig { params(value: T::Enumerable[::Comment]).void }
      #     def comments=(value); end
      #
      #     sig { params(attributes: T.untyped).returns(T.untyped) }
      #     def comments_attributes=(attributes); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
      #     def create_author(*args, &blk); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
      #     def create_author!(*args, &blk); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::Category) }
      #     def create_category(*args, &blk); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::Category) }
      #     def create_category!(*args, &blk); end
      #
      #     sig { returns(T.nilable(::User)) }
      #     def reload_author; end
      #
      #     sig { returns(T.nilable(::Category)) }
      #     def reload_category; end
      #
      #     sig { void }
      #     def reset_author; end
      #
      #     sig { void }
      #     def reset_category; end
      #   end
      # end
      # ~~~
      class ActiveRecordAssociations < Compiler
        extend T::Sig
        include Helpers::ActiveRecordConstantsHelper

        class SourceReflectionError < StandardError
        end

        class MissingConstantError < StandardError
          extend T::Sig

          sig { returns(String) }
          attr_reader :class_name

          sig { params(class_name: String).void }
          def initialize(class_name)
            @class_name = class_name
            super
          end
        end

        ConstantType = type_member { { fixed: T.class_of(ActiveRecord::Base) } }

        sig { override.void }
        def decorate
          return if constant.reflections.empty?

          root.create_path(constant) do |model|
            model.create_module(AssociationMethodsModuleName) do |mod|
              populate_nested_attribute_writers(mod)
              populate_associations(mod)
            end

            model.create_include(AssociationMethodsModuleName)
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActiveRecord::Base).reject(&:abstract_class?)
          end
        end

        private

        sig { params(mod: RBI::Scope).void }
        def populate_nested_attribute_writers(mod)
          constant.nested_attributes_options.keys.each do |association_name|
            mod.create_method(
              "#{association_name}_attributes=",
              parameters: [create_param("attributes", type: "T.untyped")],
              return_type: "T.untyped",
            )
          end
        end

        sig { params(mod: RBI::Scope).void }
        def populate_associations(mod)
          constant.reflections.each do |association_name, reflection|
            if reflection.collection?
              populate_collection_assoc_getter_setter(mod, association_name, reflection)
            else
              populate_single_assoc_getter_setter(mod, association_name, reflection)
            end
          rescue SourceReflectionError
            add_error(<<~MSG.strip)
              Cannot generate association `#{reflection.name}` on `#{constant}` since the source of the through association is missing.
            MSG
          rescue MissingConstantError => error
            add_error(<<~MSG.strip)
              Cannot generate association `#{declaration(reflection)}` on `#{constant}` since the constant `#{error.class_name}` does not exist.
            MSG
          end
        end

        sig do
          params(
            klass: RBI::Scope,
            association_name: T.any(String, Symbol),
            reflection: ReflectionType,
          ).void
        end
        def populate_single_assoc_getter_setter(klass, association_name, reflection)
          association_class = type_for(reflection)
          association_type = as_nilable_type(association_class)
          association_methods_module = constant.generated_association_methods

          klass.create_method(
            association_name.to_s,
            return_type: association_type,
          )
          klass.create_method(
            "#{association_name}=",
            parameters: [create_param("value", type: association_type)],
            return_type: "void",
          )
          klass.create_method(
            "reload_#{association_name}",
            return_type: association_type,
          )
          klass.create_method(
            "reset_#{association_name}",
            return_type: "void",
          )
          if association_methods_module.method_defined?("#{association_name}_changed?")
            klass.create_method(
              "#{association_name}_changed?",
              return_type: "T::Boolean",
            )
          end
          if association_methods_module.method_defined?("#{association_name}_previously_changed?")
            klass.create_method(
              "#{association_name}_previously_changed?",
              return_type: "T::Boolean",
            )
          end
          unless reflection.polymorphic?
            klass.create_method(
              "build_#{association_name}",
              parameters: [
                create_rest_param("args", type: "T.untyped"),
                create_block_param("blk", type: "T.untyped"),
              ],
              return_type: association_class,
            )
            klass.create_method(
              "create_#{association_name}",
              parameters: [
                create_rest_param("args", type: "T.untyped"),
                create_block_param("blk", type: "T.untyped"),
              ],
              return_type: association_class,
            )
            klass.create_method(
              "create_#{association_name}!",
              parameters: [
                create_rest_param("args", type: "T.untyped"),
                create_block_param("blk", type: "T.untyped"),
              ],
              return_type: association_class,
            )
          end
        end

        sig do
          params(
            klass: RBI::Scope,
            association_name: T.any(String, Symbol),
            reflection: ReflectionType,
          ).void
        end
        def populate_collection_assoc_getter_setter(klass, association_name, reflection)
          association_class = type_for(reflection)
          relation_class = relation_type_for(reflection)

          klass.create_method(
            association_name.to_s,
            comments: association_comments(reflection),
            return_type: relation_class,
          )
          klass.create_method(
            "#{association_name}=",
            parameters: [create_param("value", type: "T::Enumerable[#{association_class}]")],
            return_type: "void",
          )
          klass.create_method(
            "#{association_name.to_s.singularize}_ids",
            return_type: "T::Array[T.untyped]",
          )
          klass.create_method(
            "#{association_name.to_s.singularize}_ids=",
            parameters: [create_param("ids", type: "T::Array[T.untyped]")],
            return_type: "T::Array[T.untyped]",
          )
        end

        sig do
          params(
            reflection: ReflectionType,
          ).returns(String)
        end
        def type_for(reflection)
          validate_reflection!(reflection)

          return "T.untyped" if !constant.table_exists? || polymorphic_association?(reflection)

          T.must(qualified_name_of(reflection.klass))
        end

        sig do
          params(
            reflection: ReflectionType,
          ).void
        end
        def validate_reflection!(reflection)
          # Check existence of source reflection, first, since, calling
          # `.klass` also tries to go through the source reflection
          # and fails with a cryptic error, otherwise.
          if reflection.through_reflection?
            raise SourceReflectionError unless reflection.source_reflection
          end

          # For non-polymorphic reflections, `.klass` should not be raising
          # a `NameError`.
          unless reflection.polymorphic?
            reflection.klass
          end
        rescue NameError
          class_name = if reflection.through_reflection?
            reflection.send(:delegate_reflection).class_name
          else
            reflection.class_name
          end

          raise MissingConstantError, class_name
        end

        sig { params(reflection: ReflectionType).returns(T.nilable(String)) }
        def declaration(reflection)
          case reflection
          when ActiveRecord::Reflection::HasOneReflection
            "has_one :#{reflection.name}"
          when ActiveRecord::Reflection::HasManyReflection
            "has_many :#{reflection.name}"
          when ActiveRecord::Reflection::HasAndBelongsToManyReflection
            "has_and_belongs_to_many :#{reflection.name}"
          when ActiveRecord::Reflection::BelongsToReflection
            "belongs_to :#{reflection.name}"
          when ActiveRecord::Reflection::ThroughReflection
            delegate_reflection = reflection.send(:delegate_reflection)
            declaration = declaration(delegate_reflection)
            through_name = delegate_reflection.options[:through]

            "#{declaration}, through: :#{through_name}"
          end
        end

        sig { params(reflection: ReflectionType).returns(T::Array[RBI::Comment]) }
        def association_comments(reflection)
          anchor_name = case reflection
          when ActiveRecord::Reflection::HasOneReflection
            "the-has-one-association"
          when ActiveRecord::Reflection::HasManyReflection
            "the-has-many-association"
          when ActiveRecord::Reflection::HasAndBelongsToManyReflection
            "the-has-and-belongs-to-many-association"
          when ActiveRecord::Reflection::BelongsToReflection
            "the-belongs-to-association"
          when ActiveRecord::Reflection::ThroughReflection
            delegate_reflection = reflection.send(:delegate_reflection)
            declaration = declaration(delegate_reflection)
            if T.must(declaration).match?("has_one")
              "the-has-one-through-association"
            else
              "the-has-many-through-association"
            end
          end

          if anchor_name
            url = "https://guides.rubyonrails.org/association_basics.html##{anchor_name}"
            association_name = anchor_name.sub(/^the-(.*)-association$/, '\1')
            comment = <<~MSG
              This method is created by ActiveRecord on the `#{reflection.active_record.name}` class because it declared `#{declaration(reflection)}`.
              🔗 [Rails guide for `#{association_name.gsub("-", "_")}` association](#{url})
            MSG
            [RBI::Comment.new(comment)]
          else
            []
          end
        end

        sig do
          params(
            reflection: ReflectionType,
          ).returns(String)
        end
        def relation_type_for(reflection)
          validate_reflection!(reflection)

          relations_enabled = compiler_enabled?("ActiveRecordRelations")
          polymorphic_association = !constant.table_exists? || polymorphic_association?(reflection)

          if relations_enabled
            if polymorphic_association
              "ActiveRecord::Associations::CollectionProxy"
            else
              "#{qualified_name_of(reflection.klass)}::#{AssociationsCollectionProxyClassName}"
            end
          elsif polymorphic_association
            "ActiveRecord::Associations::CollectionProxy[T.untyped]"
          else
            "::ActiveRecord::Associations::CollectionProxy[#{qualified_name_of(reflection.klass)}]"
          end
        end

        sig do
          params(
            reflection: ReflectionType,
          ).returns(T::Boolean)
        end
        def polymorphic_association?(reflection)
          if reflection.through_reflection?
            polymorphic_association?(reflection.source_reflection)
          else
            !!reflection.polymorphic?
          end
        end
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

require "tapioca/dsl/helpers/active_record_column_type_helper"
require "tapioca/dsl/helpers/active_record_constants_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::DelegatedTypes` defines RBI files for subclasses of
      # [`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html).
      # This compiler is only responsible for defining the methods that would be created for delegated_types that
      # are defined in the Active Record model.
      #
      # For example, with the following model class:
      #
      # ~~~rb
      # class Entry < ActiveRecord::Base
      #   delegated_type :entryable, types: %w[ Message Comment ]
      # end
      # ~~~
      #
      # this compiler will produce the following methods in the RBI file
      # `entry.rbi`:
      #
      # ~~~rbi
      # # entry.rbi
      # # typed: true
      #
      # class Entry
      #   include GeneratedDelegatedTypeMethods
      #
      #   module GeneratedDelegatedTypeMethods
      #     sig { params(args: T.untyped).returns(T.any(Message, Comment)) }
      #     def build_entryable(*args); end
      #
      #     sig { returns(Class) }
      #     def entryable_class; end
      #
      #     sig { returns(ActiveSupport::StringInquirer) }
      #     def entryable_name; end
      #
      #     sig { returns(T::Boolean) }
      #     def message?; end
      #
      #     sig { returns(T.nilable(Message)) }
      #     def message; end
      #
      #     sig { returns(T.nilable(Integer)) }
      #     def message_id; end
      #
      #     sig { returns(T::Boolean) }
      #     def comment?; end
      #
      #     sig { returns(T.nilable(Comment)) }
      #     def comment; end
      #
      #     sig { returns(T.nilable(Integer)) }
      #     def comment_id; end
      #   end
      # end
      #
      # ~~~
      class ActiveRecordDelegatedTypes < Compiler
        extend T::Sig
        include Helpers::ActiveRecordConstantsHelper

        ConstantType = type_member { { fixed: T.all(T.class_of(ActiveRecord::Base), Extensions::ActiveRecord) } }

        sig { override.void }
        def decorate
          return if constant.__tapioca_delegated_types.nil?

          root.create_path(constant) do |model|
            model.create_module(DelegatedTypesModuleName) do |mod|
              constant.__tapioca_delegated_types.each do |role, data|
                types = data.fetch(:types)
                options = data.fetch(:options, {})
                populate_role_accessors(mod, role, types)
                populate_type_helpers(mod, role, types, options)
              end
            end

            model.create_include(DelegatedTypesModuleName)
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

        sig { params(mod: RBI::Scope, role: Symbol, types: T::Array[String]).void }
        def populate_role_accessors(mod, role, types)
          mod.create_method(
            "#{role}_name",
            parameters: [],
            return_type: "ActiveSupport::StringInquirer",
          )

          mod.create_method(
            "#{role}_class",
            parameters: [],
            return_type: "T::Class[T.anything]",
          )

          mod.create_method(
            "build_#{role}",
            parameters: [create_rest_param("args", type: "T.untyped")],
            return_type: "T.any(#{types.join(", ")})",
          )
        end

        sig { params(mod: RBI::Scope, role: Symbol, types: T::Array[String], options: T::Hash[Symbol, T.untyped]).void }
        def populate_type_helpers(mod, role, types, options)
          types.each do |type|
            populate_type_helper(mod, role, type, options)
          end
        end

        sig { params(mod: RBI::Scope, role: Symbol, type: String, options: T::Hash[Symbol, T.untyped]).void }
        def populate_type_helper(mod, role, type, options)
          singular   = type.tableize.tr("/", "_").singularize
          query      = "#{singular}?"
          primary_key = options[:primary_key] || "id"
          role_id = options[:foreign_key] || "#{role}_id"

          getter_type, _ = Helpers::ActiveRecordColumnTypeHelper.new(constant).type_for(role_id.to_s)

          mod.create_method(
            query,
            parameters: [],
            return_type: "T::Boolean",
          )

          mod.create_method(
            singular,
            parameters: [],
            return_type: "T.nilable(#{type})",
          )

          mod.create_method(
            "#{singular}_#{primary_key}",
            parameters: [],
            return_type: as_nilable_type(getter_type),
          )
        end
      end
    end
  end
end

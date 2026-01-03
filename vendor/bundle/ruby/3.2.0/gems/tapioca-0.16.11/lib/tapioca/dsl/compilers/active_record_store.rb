# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

require "tapioca/dsl/helpers/active_record_constants_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordStore` decorates RBI files for all
      # classes that use [`ActiveRecord::Store`](https://api.rubyonrails.org/classes/ActiveRecord/Store.html).
      #
      # For example, with the following class:
      #
      # ~~~rb
      # class User < ActiveRecord::Base
      #   store :settings, accessors: :theme
      #   store_accessor :settings, :power_source, prefix: :prefs
      # end
      # ~~~
      #
      # this compiler will produce an RBI file with the following content:
      # ~~~rbi
      # # typed: true
      #
      # class User
      #   include GeneratedStoredAttributesMethods
      #
      #   module GeneratedStoredAttributesMethods
      #     sig { returns(T.untyped) }
      #     def prefs_power_source; end
      #
      #     sig { params(value: T.untyped).returns(T.untyped) }
      #     def prefs_power_source=(value); end
      #
      #     sig { returns(T.untyped) }
      #     def prefs_power_source_before_last_save; end
      #
      #     sig { returns(T.untyped) }
      #     def prefs_power_source_change; end
      #
      #     sig { returns(T::Boolean) }
      #     def prefs_power_source_changed?; end
      #
      #     sig { returns(T.untyped) }
      #     def prefs_power_source_was; end
      #
      #     sig { returns(T.untyped) }
      #     def saved_change_to_prefs_power_source; end
      #
      #     sig { returns(T::Boolean) }
      #     def saved_change_to_prefs_power_source?; end
      #
      #     sig { returns(T.untyped) }
      #     def saved_change_to_theme; end
      #
      #     sig { returns(T::Boolean) }
      #     def saved_change_to_theme?; end
      #
      #     sig { returns(T.untyped) }
      #     def theme; end
      #
      #     sig { params(value: T.untyped).returns(T.untyped) }
      #     def theme=(value); end
      #
      #     sig { returns(T.untyped) }
      #     def theme_before_last_save; end
      #
      #     sig { returns(T.untyped) }
      #     def theme_change; end
      #
      #     sig { returns(T::Boolean) }
      #     def theme_changed?; end
      #
      #     sig { returns(T.untyped) }
      #     def theme_was; end
      #   end
      # end
      # ~~~
      class ActiveRecordStore < Compiler
        extend T::Sig
        include Helpers::ActiveRecordConstantsHelper

        ConstantType = type_member { { fixed: T.all(T.class_of(ActiveRecord::Base), Extensions::ActiveRecord) } }

        sig { override.void }
        def decorate
          return if constant.__tapioca_stored_attributes.nil?

          root.create_path(constant) do |klass|
            klass.create_module(StoredAttributesModuleName) do |mod|
              constant.__tapioca_stored_attributes.each do |store_attribute, keys, prefix, suffix|
                accessor_prefix =
                  case prefix
                  when String, Symbol
                    "#{prefix}_"
                  when TrueClass
                    "#{store_attribute}_"
                  else
                    ""
                  end
                accessor_suffix =
                  case suffix
                  when String, Symbol
                    "_#{suffix}"
                  when TrueClass
                    "_#{store_attribute}"
                  else
                    ""
                  end

                keys.flatten.map { |key| "#{accessor_prefix}#{key}#{accessor_suffix}" }.each do |accessor_key|
                  mod.create_method(
                    "#{accessor_key}=",
                    parameters: [create_param("value", type: "T.untyped")],
                    return_type: "T.untyped",
                  )
                  mod.create_method(accessor_key, return_type: "T.untyped")
                  mod.create_method("#{accessor_key}_changed?", return_type: "T::Boolean")
                  mod.create_method("#{accessor_key}_change", return_type: "T.untyped")
                  mod.create_method("#{accessor_key}_was", return_type: "T.untyped")
                  mod.create_method("saved_change_to_#{accessor_key}?", return_type: "T::Boolean")
                  mod.create_method("saved_change_to_#{accessor_key}", return_type: "T.untyped")
                  mod.create_method("#{accessor_key}_before_last_save", return_type: "T.untyped")
                end
              end
            end

            klass.create_include(StoredAttributesModuleName)
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActiveRecord::Base).reject(&:abstract_class?)
          end
        end
      end
    end
  end
end

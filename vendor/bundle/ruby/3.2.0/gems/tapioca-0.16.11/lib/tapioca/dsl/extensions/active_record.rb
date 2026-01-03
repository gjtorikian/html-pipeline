# typed: true
# frozen_string_literal: true

begin
  require "active_support"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      module Extensions
        module ActiveRecord
          attr_reader :__tapioca_delegated_types

          def delegated_type(role, types:, **options)
            @__tapioca_delegated_types ||= {}
            @__tapioca_delegated_types[role] = { types: types, options: options }

            super
          end

          attr_reader :__tapioca_secure_tokens

          def has_secure_token(attribute = :token, **)
            @__tapioca_secure_tokens ||= []
            @__tapioca_secure_tokens << attribute

            super
          end

          attr_reader :__tapioca_stored_attributes

          def store_accessor(store_attribute, *keys, prefix: nil, suffix: nil)
            @__tapioca_stored_attributes ||= []
            @__tapioca_stored_attributes << [store_attribute, keys, prefix, suffix]

            super
          end

          ::ActiveSupport.on_load(:active_record) do
            ::ActiveRecord::Base.singleton_class.prepend(::Tapioca::Dsl::Compilers::Extensions::ActiveRecord)
          end
        end
      end
    end
  end
end

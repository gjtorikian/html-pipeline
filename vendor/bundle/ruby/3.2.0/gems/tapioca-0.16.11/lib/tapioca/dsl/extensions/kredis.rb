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
        module Kredis
          attr_reader :__tapioca_kredis_types

          def kredis_proxy(name, key: nil, config: :shared, after_change: nil)
            collect_kredis_type(name, "Kredis::Types::Proxy")
            super
          end

          def kredis_string(name, key: nil, default: nil, config: :shared, after_change: nil, expires_in: nil)
            collect_kredis_type(name, "Kredis::Types::Scalar")
            super
          end

          def kredis_integer(name, key: nil, default: nil, config: :shared, after_change: nil, expires_in: nil)
            collect_kredis_type(name, "Kredis::Types::Scalar")
            super
          end

          def kredis_decimal(name, key: nil, default: nil, config: :shared, after_change: nil, expires_in: nil)
            collect_kredis_type(name, "Kredis::Types::Scalar")
            super
          end

          def kredis_datetime(name, key: nil, default: nil, config: :shared, after_change: nil, expires_in: nil)
            collect_kredis_type(name, "Kredis::Types::Scalar")
            super
          end

          def kredis_flag(name, key: nil, default: nil, config: :shared, after_change: nil, expires_in: nil)
            collect_kredis_type(name, "Kredis::Types::Flag")
            super
          end

          def kredis_float(name, key: nil, default: nil, config: :shared, after_change: nil, expires_in: nil)
            collect_kredis_type(name, "Kredis::Types::Scalar")
            super
          end

          def kredis_enum(name, key: nil, values:, default:, config: :shared, after_change: nil)
            collect_kredis_type(name, "Kredis::Types::Enum", values: values)
            super
          end

          def kredis_json(name, key: nil, default: nil, config: :shared, after_change: nil, expires_in: nil)
            collect_kredis_type(name, "Kredis::Types::Scalar")
            super
          end

          def kredis_list(name, key: nil, default: nil, typed: :string, config: :shared, after_change: nil)
            collect_kredis_type(name, "Kredis::Types::List")
            super
          end

          def kredis_unique_list(name, limit: nil, key: nil, default: nil, typed: :string, config: :shared,
            after_change: nil)
            collect_kredis_type(name, "Kredis::Types::UniqueList")
            super
          end

          def kredis_set(name, key: nil, default: nil, typed: :string, config: :shared, after_change: nil)
            collect_kredis_type(name, "Kredis::Types::Set")
            super
          end

          def kredis_slot(name, key: nil, config: :shared, after_change: nil)
            collect_kredis_type(name, "Kredis::Types::Slots")
            super
          end

          def kredis_slots(name, available:, key: nil, config: :shared, after_change: nil)
            collect_kredis_type(name, "Kredis::Types::Slots")
            super
          end

          def kredis_counter(name, key: nil, default: nil, config: :shared, after_change: nil, expires_in: nil)
            collect_kredis_type(name, "Kredis::Types::Counter")
            super
          end

          def kredis_hash(name, key: nil, default: nil, typed: :string, config: :shared, after_change: nil)
            collect_kredis_type(name, "Kredis::Types::Hash")
            super
          end

          def kredis_boolean(name, key: nil, default: nil, config: :shared, after_change: nil, expires_in: nil)
            collect_kredis_type(name, "Kredis::Types::Scalar")
            super
          end

          private

          def collect_kredis_type(method, type, values: nil)
            @__tapioca_kredis_types ||= {}
            @__tapioca_kredis_types[method.to_s] = { type: type, values: values }
          end

          ::ActiveSupport.on_load(:before_configuration) do
            next unless defined?(::Kredis::Attributes::ClassMethods)

            ::Kredis::Attributes::ClassMethods.prepend(::Tapioca::Dsl::Compilers::Extensions::Kredis)
          end
        end
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

return unless defined?(Kredis::Attributes)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Kredis` decorates RBI files for all
      # classes that include [`Kredis::Attributes`](https://github.com/rails/kredis/blob/main/lib/kredis/attributes.rb).
      #
      # For example, with the following class:
      #
      # ~~~rb
      # class Person < ApplicationRecord
      #   kredis_list :names
      #   kredis_flag :awesome
      #   kredis_counter :steps, expires_in: 1.hour
      #   kredis_enum :morning, values: %w[ bright blue black ], default: "bright"
      # end
      # ~~~
      #
      # this compiler will produce an RBI file with the following content:
      # ~~~rbi
      # # typed: true
      #
      # class Person
      #   module GeneratedKredisAttributeMethods
      #     sig { returns(Kredis::Types::Flag) }
      #     def awesome; end
      #
      #     sig { returns(T::Boolean) }
      #     def awesome?; end
      #
      #     sig { returns(PrivateEnumMorning) }
      #     def morning; end
      #
      #     sig { returns(Kredis::Types::List) }
      #     def names; end
      #
      #     sig { returns(Kredis::Types::Counter) }
      #     def steps; end
      #
      #     class PrivateEnumMorning < Kredis::Types::Enum
      #       sig { void }
      #       def black!; end
      #
      #       sig { returns(T::Boolean) }
      #       def black?; end
      #
      #       sig { void }
      #       def blue!; end
      #
      #       sig { returns(T::Boolean) }
      #       def blue?; end
      #
      #       sig { void }
      #       def bright!; end
      #
      #       sig { returns(T::Boolean) }
      #       def bright?; end
      #     end
      #   end
      # end
      # ~~~
      class Kredis < Compiler
        extend T::Sig

        ConstantType = type_member do
          { fixed: T.all(T::Class[::Kredis::Attributes], ::Kredis::Attributes::ClassMethods, Extensions::Kredis) }
        end

        sig { override.void }
        def decorate
          return if constant.__tapioca_kredis_types.nil?

          module_name = "GeneratedKredisAttributeMethods"

          root.create_path(constant) do |model|
            model.create_module(module_name) do |mod|
              constant.__tapioca_kredis_types.each do |method, data|
                generate_methods(mod, method, data)
              end
            end
            model.create_include(module_name)
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes
              .grep(::Kredis::Attributes::ClassMethods)
              .reject { |klass| klass.to_s == "ActiveRecord::Base" || klass.try(:abstract_class?) }
          end
        end

        private

        sig { params(mod: RBI::Scope, method: String, data: T::Hash[Symbol, T.untyped]).void }
        def generate_methods(mod, method, data)
          return_type = data.fetch(:type)
          case return_type
          when "Kredis::Types::Enum"
            klass_name = "PrivateEnum#{method.split("_").map(&:capitalize).join}"
            create_enum_class(mod, klass_name, data.fetch(:values))
            return_type = klass_name
          when "Kredis::Types::Flag"
            mod.create_method("#{method}?", return_type: "T::Boolean")
          end

          mod.create_method(method, return_type: return_type)
        end

        sig { params(mod: RBI::Scope, klass_name: String, values: T::Array[T.untyped]).void }
        def create_enum_class(mod, klass_name, values)
          klass = mod.create_class(klass_name, superclass_name: "Kredis::Types::Enum")
          values.each do |value|
            klass.create_method("#{value}!", return_type: "void")
            klass.create_method("#{value}?", return_type: "T::Boolean")
          end
        end
      end
    end
  end
end

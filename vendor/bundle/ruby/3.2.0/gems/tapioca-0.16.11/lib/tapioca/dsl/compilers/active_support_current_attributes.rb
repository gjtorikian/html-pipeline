# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveSupport::CurrentAttributes)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveSupportCurrentAttributes` decorates RBI files for all
      # subclasses of
      # [`ActiveSupport::CurrentAttributes`](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html).
      #
      # For example, with the following singleton class
      #
      # ~~~rb
      # class Current < ActiveSupport::CurrentAttributes
      #   extend T::Sig
      #
      #   attribute :account
      #
      #   def helper
      #     # ...
      #   end
      #
      #   sig { params(user_id: Integer).void }
      #   def authenticate(user_id)
      #     # ...
      #   end
      # end
      # ~~~
      #
      # this compiler will produce an RBI file with the following content:
      # ~~~rbi
      # # typed: true
      #
      # class Current
      #   include GeneratedAttributeMethods
      #
      #   class << self
      #     sig { returns(T.untyped) }
      #     def account; end
      #
      #     sig { params(account: T.untyped).returns(T.untyped) }
      #     def account=(account); end
      #
      #     sig { params(user_id: Integer).void }
      #     def authenticate(user_id); end
      #
      #     sig { returns(T.untyped) }
      #     def helper; end
      #   end
      #
      #   module GeneratedAttributeMethods
      #     sig { returns(T.untyped) }
      #     def account; end
      #
      #     sig { params(account: T.untyped).returns(T.untyped) }
      #     def account=(account); end
      #   end
      # end
      # ~~~
      class ActiveSupportCurrentAttributes < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ActiveSupport::CurrentAttributes) } }

        sig { override.void }
        def decorate
          dynamic_methods = dynamic_methods_of_constant
          instance_methods = instance_methods_of_constant - dynamic_methods
          return if dynamic_methods.empty? && instance_methods.empty?

          root.create_path(constant) do |current_attributes|
            current_attributes_methods_name = "GeneratedAttributeMethods"
            current_attributes.create_module(current_attributes_methods_name) do |generated_attribute_methods|
              dynamic_methods.each do |method|
                method = method.to_s
                # We want to generate each method both on the class
                generate_method(current_attributes, method, class_method: true)
                # and on the instance
                generate_method(generated_attribute_methods, method, class_method: false)
              end

              instance_methods.each do |method|
                # instance methods are only elevated to class methods
                # no need to add separate instance methods for them
                method = constant.instance_method(method)
                create_method_from_def(current_attributes, method, class_method: true)
              end
            end

            current_attributes.create_include(current_attributes_methods_name)
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActiveSupport::CurrentAttributes)
          end
        end

        private

        sig { returns(T::Array[Symbol]) }
        def dynamic_methods_of_constant
          constant.instance_variable_get(:@generated_attribute_methods)&.instance_methods(false) || []
        end

        sig { returns(T::Array[Symbol]) }
        def instance_methods_of_constant
          constant.instance_methods(false)
        end

        sig { params(klass: RBI::Scope, method: String, class_method: T::Boolean).void }
        def generate_method(klass, method, class_method:)
          method_def = if class_method
            constant.method(method)
          else
            constant.instance_method(method)
          end

          create_method_from_def(klass, method_def, class_method: class_method)
        end
      end
    end
  end
end

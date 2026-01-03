# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveModel::SecurePassword)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveModelSecurePassword` decorates RBI files for all
      # classes that use [`ActiveModel::SecurePassword`](http://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html).
      #
      # For example, with the following class:
      #
      # ~~~rb
      # class User
      #   include ActiveModel::SecurePassword
      #
      #   has_secure_password
      #   has_secure_password :token
      # end
      # ~~~
      #
      # this compiler will produce an RBI file with the following content:
      # ~~~rbi
      # # typed: true
      #
      # class User
      #   sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
      #   def authenticate(unencrypted_password); end
      #
      #   sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
      #   def authenticate_password(unencrypted_password); end
      #
      #   sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
      #   def authenticate_token(unencrypted_password); end
      #
      #   sig { returns(T.untyped) }
      #   def password; end
      #
      #   sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
      #   def password=(unencrypted_password); end
      #
      #   sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
      #   def password_confirmation=(unencrypted_password); end
      #
      #   sig { returns(T.untyped) }
      #   def token; end
      #
      #   sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
      #   def token=(unencrypted_password); end
      #
      #   sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
      #   def token_confirmation=(unencrypted_password); end
      # end
      # ~~~
      class ActiveModelSecurePassword < Compiler
        extend T::Sig

        ConstantType = type_member do
          { fixed: T.all(T::Class[::ActiveModel::SecurePassword], ::ActiveModel::SecurePassword::ClassMethods) }
        end

        sig { override.void }
        def decorate
          instance_methods_modules = if constant < ActiveModel::SecurePassword::InstanceMethodsOnActivation
            # pre Rails 6.0, this used to be a single static module
            [ActiveModel::SecurePassword::InstanceMethodsOnActivation]
          else
            # post Rails 6.0, this is now using a dynamic module builder pattern
            # and we can have multiple different ones included into the model
            constant.ancestors.grep(ActiveModel::SecurePassword::InstanceMethodsOnActivation)
          end

          return if instance_methods_modules.empty?

          methods = instance_methods_modules.flat_map { |mod| mod.instance_methods(false) }
          return if methods.empty?

          root.create_path(constant) do |klass|
            methods.each do |method|
              if method == :authenticate || method.start_with?("authenticate_")
                klass.create_method(
                  method.to_s,
                  parameters: [create_param("unencrypted_password", type: "T.untyped")],
                  return_type: "T.any(#{constant}, FalseClass)",
                )
              else
                create_method_from_def(klass, constant.instance_method(method))
              end
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            # This selects all classes that are `ActiveModel::SecurePassword::ClassMethods === klass`.
            # In other words, we select all classes that have `ActiveModel::SecurePassword::ClassMethods`
            # as an ancestor of its singleton class, i.e. all classes that have extended the
            # `ActiveModel::SecurePassword::ClassMethods` module.
            all_classes.grep(::ActiveModel::SecurePassword::ClassMethods)
          end
        end
      end
    end
  end
end

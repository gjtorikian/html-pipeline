# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

require "tapioca/dsl/helpers/active_record_constants_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveModelSecurePassword` decorates RBI files for all
      # classes that use [`ActiveRecord::SecureToken`](https://api.rubyonrails.org/classes/ActiveRecord/SecureToken/ClassMethods.html).
      #
      # For example, with the following class:
      #
      # ~~~rb
      # class User < ActiveRecord::Base
      #   has_secure_token
      #   has_secure_token :auth_token, length: 36
      # end
      # ~~~
      #
      # this compiler will produce an RBI file with the following content:
      # ~~~rbi
      # # typed: true
      #
      # class User
      #   sig { returns(T::Boolean) }
      #   def regenerate_token; end
      #
      #   sig { returns(T::Boolean) }
      #   def regenerate_auth_token; end
      # end
      # ~~~
      class ActiveRecordSecureToken < Compiler
        extend T::Sig
        include Helpers::ActiveRecordConstantsHelper

        ConstantType = type_member { { fixed: T.all(T.class_of(ActiveRecord::Base), Extensions::ActiveRecord) } }

        sig { override.void }
        def decorate
          return if constant.__tapioca_secure_tokens.nil?

          root.create_path(constant) do |model|
            model.create_module(SecureTokensModuleName) do |mod|
              constant.__tapioca_secure_tokens.each do |attribute|
                mod.create_method(
                  "regenerate_#{attribute}",
                  return_type: "T::Boolean",
                )
              end
            end

            model.create_include(SecureTokensModuleName)
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

# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveJob::Base)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveJob` generates RBI files for subclasses of
      # [`ActiveJob::Base`](https://api.rubyonrails.org/classes/ActiveJob/Base.html).
      #
      # For example, with the following `ActiveJob` subclass:
      #
      # ~~~rb
      # class NotifyUserJob < ActiveJob::Base
      #   sig { params(user: User).returns(Mail) }
      #   def perform(user)
      #     # ...
      #   end
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `notify_user_job.rbi` with the following content:
      #
      # ~~~rbi
      # # notify_user_job.rbi
      # # typed: true
      # class NotifyUserJob
      #   sig do
      #     params(
      #       user: User,
      #       block: T.nilable(T.proc.params(job: NotifyUserJob).void),
      #     ).returns(T.any(NotifyUserJob, FalseClass))
      #   end
      #   def self.perform_later(user, &block); end
      #
      #   sig { params(user: User).returns(Mail) }
      #   def self.perform_now(user); end
      # end
      # ~~~
      class ActiveJob < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ActiveJob::Base) } }

        sig { override.void }
        def decorate
          return unless constant.instance_methods(false).include?(:perform)

          root.create_path(constant) do |job|
            method = constant.instance_method(:perform)
            constant_name = name_of(constant)
            parameters = compile_method_parameters_to_rbi(method)
            return_type = compile_method_return_type_to_rbi(method)

            job.create_method(
              "perform_later",
              parameters: perform_later_parameters(parameters, constant_name),
              return_type: "T.any(#{constant_name}, FalseClass)",
              class_method: true,
            )

            job.create_method(
              "perform_now",
              parameters: parameters,
              return_type: return_type,
              class_method: true,
            )
          end
        end

        private

        sig do
          params(
            parameters: T::Array[RBI::TypedParam],
            constant_name: T.nilable(String),
          ).returns(T::Array[RBI::TypedParam])
        end
        def perform_later_parameters(parameters, constant_name)
          if ::Gem::Requirement.new(">= 7.0").satisfied_by?(::ActiveJob.gem_version)
            parameters.reject! { |typed_param| RBI::BlockParam === typed_param.param }
            parameters + [create_block_param(
              "block",
              type: "T.nilable(T.proc.params(job: #{constant_name}).void)",
            )]
          else
            parameters
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActiveJob::Base)
          end
        end
      end
    end
  end
end

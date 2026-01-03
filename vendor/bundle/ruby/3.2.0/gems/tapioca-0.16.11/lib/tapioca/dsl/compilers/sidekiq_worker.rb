# typed: strict
# frozen_string_literal: true

return unless defined?(Sidekiq::Worker)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::SidekiqWorker` generates RBI files classes that include
      # [`Sidekiq::Worker`](https://github.com/mperham/sidekiq/wiki/Getting-Started).
      #
      # For example, with the following class that includes `Sidekiq::Worker`:
      #
      # ~~~rb
      # class NotifierWorker
      #   include Sidekiq::Worker
      #   def perform(customer_id)
      #     # ...
      #   end
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `notifier_worker.rbi` with the following content:
      #
      # ~~~rbi
      # # notifier_worker.rbi
      # # typed: true
      # class NotifierWorker
      #   sig { params(customer_id: T.untyped).returns(String) }
      #   def self.perform_async(customer_id); end
      #
      #   sig { params(interval: T.any(DateTime, Time), customer_id: T.untyped).returns(String) }
      #   def self.perform_at(interval, customer_id); end
      #
      #   sig { params(interval: Numeric, customer_id: T.untyped).returns(String) }
      #   def self.perform_in(interval, customer_id); end
      # end
      # ~~~
      class SidekiqWorker < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::Sidekiq::Worker) } }

        sig { override.void }
        def decorate
          return unless constant.instance_methods.include?(:perform)

          root.create_path(constant) do |worker|
            method_def = constant.instance_method(:perform)

            async_params = compile_method_parameters_to_rbi(method_def)

            # `perform_at` and is just an alias for `perform_in` so both methods technically
            # accept a datetime, time, or numeric but we're typing them differently so they
            # semantically make sense.
            at_params = [
              create_param("interval", type: "T.any(DateTime, Time)"),
              *async_params,
            ]
            in_params = [
              create_param("interval", type: "Numeric"),
              *async_params,
            ]

            generate_perform_method(worker, "perform_async", async_params)
            generate_perform_method(worker, "perform_at", at_params)
            generate_perform_method(worker, "perform_in", in_params)
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| Sidekiq::Worker > c }
          end
        end

        private

        sig do
          params(
            worker: RBI::Scope,
            method_name: String,
            parameters: T::Array[RBI::TypedParam],
          ).void
        end
        def generate_perform_method(worker, method_name, parameters)
          if constant.method(method_name.to_sym).owner == Sidekiq::Worker::ClassMethods
            worker.create_method(method_name, parameters: parameters, return_type: "String", class_method: true)
          end
        end
      end
    end
  end
end

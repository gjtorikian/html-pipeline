# typed: strict
# frozen_string_literal: true

return unless defined?(AASM)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::AASM` generate types for AASM state machines.
      # This gem dynamically defines constants and methods at runtime. For
      # example, given a class:
      #
      #   class MyClass
      #     include AASM
      #
      #     aasm do
      #       state :sleeping, initial: true
      #       state :running, :cleaning
      #
      #       event :run do
      #         transitions from: :sleeping, to: :running
      #       end
      #     end
      #   end
      #
      # This will result in the following constants being defined:
      #
      #   STATE_SLEEPING, STATE_RUNNING, STATE_CLEANING
      #
      # and the following methods being defined:
      #
      #   sleeping?, running?, cleaning?
      #   run, run!, run_without_validation!, may_run?
      #
      class AASM < Compiler
        extend T::Sig

        # Taken directly from the AASM::Core::Event class, here:
        # https://github.com/aasm/aasm/blob/0e03746/lib/aasm/core/event.rb#L21-L29
        EVENT_CALLBACKS =
          T.let(
            [
              "after",
              "after_commit",
              "after_transaction",
              "before",
              "before_transaction",
              "ensure",
              "error",
              "before_success",
              "success",
            ].freeze,
            T::Array[String],
          )

        # Taken directly from the AASM::Base class, here:
        # https://github.com/aasm/aasm/blob/0e03746a2b86558ee1bf7bd7db873938cbb3b29b/lib/aasm/base.rb#L145-L171
        GLOBAL_CALLBACKS =
          T.let(
            [
              "after_all_transitions",
              "after_all_transactions",
              "before_all_transactions",
              "before_all_events",
              "after_all_events",
              "error_on_all_events",
              "ensure_on_all_events",
            ].freeze,
            T::Array[String],
          )

        TRANSITION_CALLBACKS =
          T.let(
            [
              "on_transition",
              "guard",
              "after",
              "success",
            ].freeze,
            T::Array[String],
          )

        ConstantType = type_member { { fixed: T.all(T::Class[::AASM], ::AASM::ClassMethods) } }

        sig { override.void }
        def decorate
          state_machine_store = ::AASM::StateMachineStore.fetch(constant)
          return unless state_machine_store

          state_machines = state_machine_store.machine_names.map { |n| constant.aasm(n) }
          return if state_machines.all? { |m| m.states.empty? }

          root.create_path(constant) do |model|
            state_machines.each do |state_machine|
              namespace = state_machine.__send__(:namespace)

              # Create all of the constants and methods for each state
              state_machine.states.each do |state|
                name = state.name
                name = "#{namespace}_#{name}" if namespace

                model.create_constant("STATE_#{name.upcase}", value: "T.let(T.unsafe(nil), Symbol)")
                model.create_method("#{name}?", return_type: "T::Boolean")
              end

              # Create all of the methods for each event
              parameters = [create_rest_param("opts", type: "T.untyped")]
              state_machine.events.each do |event|
                model.create_method(event.name.to_s, parameters: parameters)
                model.create_method("#{event.name}!", parameters: parameters)
                model.create_method("#{event.name}_without_validation!", parameters: parameters)
                model.create_method("may_#{event.name}?", return_type: "T::Boolean")

                # For events, if there's a namespace the default methods are created in addition to
                # namespaced ones.
                next unless namespace

                name = "#{event.name}_#{namespace}"

                model.create_method(name.to_s, parameters: parameters)
                model.create_method("#{name}!", parameters: parameters)
                model.create_method("may_#{name}?", return_type: "T::Boolean")

                # There's no namespaced method created for `_without_validation`, so skip
                # defining a method for:
                #   "#{name}_without_validation!"
              end
            end

            # Create the overall state machine method, which will return an
            # instance of the PrivateAASMMachine class.
            model.create_method(
              "aasm",
              parameters: [
                create_rest_param("args", type: "T.untyped"),
                create_block_param("block", type: "T.nilable(T.proc.bind(PrivateAASMMachine).void)"),
              ],
              return_type: "PrivateAASMMachine",
              class_method: true,
            )

            # Create a private machine class that we can pass around for the
            # purpose of binding various procs passed to methods without having
            # to explicitly bind self in each one.
            model.create_class("PrivateAASMMachine", superclass_name: "AASM::Base") do |machine|
              machine.create_method(
                "event",
                parameters: [
                  create_param("name", type: "T.untyped"),
                  create_opt_param("options", default: "nil", type: "T.untyped"),
                  create_block_param("block", type: "T.proc.bind(PrivateAASMEvent).void"),
                ],
              )

              constant_name = name_of(constant)

              GLOBAL_CALLBACKS.each do |method|
                machine.create_method(
                  method,
                  parameters: [
                    create_rest_param("callbacks", type: "T.any(String, Symbol, T::Class[T.anything], Proc)"),
                    create_block_param("block", type: "T.nilable(T.proc.bind(#{constant_name}).void)"),
                  ],
                )
              end

              # Create a private event class that we can pass around for the
              # purpose of binding all of the callbacks without having to
              # explicitly bind self in each one.
              machine.create_class("PrivateAASMEvent", superclass_name: "AASM::Core::Event") do |event|
                EVENT_CALLBACKS.each do |method|
                  event.create_method(
                    method,
                    parameters: [
                      create_opt_param("symbol", type: "T.nilable(Symbol)", default: "nil"),
                      create_block_param(
                        "block",
                        type: "T.nilable(T.proc.bind(#{constant_name}).params(opts: T.untyped).void)",
                      ),
                    ],
                  )
                end

                event.create_method(
                  "transitions",
                  parameters: [
                    create_opt_param("definitions", default: "nil", type: "T.untyped"),
                    create_block_param("block", type: "T.nilable(T.proc.bind(PrivateAASMTransition).void)"),
                  ],
                )
              end

              machine.create_class("PrivateAASMTransition", superclass_name: "AASM::Core::Transition") do |transition|
                TRANSITION_CALLBACKS.each do |method|
                  return_type = "T.untyped"
                  return_type = "T::Boolean" if method == "guard"

                  transition.create_method(
                    method,
                    parameters: [
                      create_block_param(
                        "block",
                        type: "T.nilable(T.proc.bind(#{constant_name}).params(opts: T.untyped).void)",
                      ),
                    ],
                    return_type: return_type,
                  )
                end
              end
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            T.cast(ObjectSpace.each_object(::AASM::ClassMethods), T::Enumerable[Module])
          end
        end
      end
    end
  end
end

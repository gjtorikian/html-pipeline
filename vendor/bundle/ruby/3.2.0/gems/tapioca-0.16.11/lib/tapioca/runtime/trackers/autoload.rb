# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module Autoload
        extend Tracker
        extend T::Sig

        NOOP_METHOD = ->(*_args, **_kwargs, &_block) {}

        @constant_names_registered_for_autoload = T.let([], T::Array[String])

        class << self
          extend T::Sig

          sig { void }
          def eager_load_all!
            with_disabled_exits do
              until @constant_names_registered_for_autoload.empty?
                # Grab the next constant name
                constant_name = T.must(@constant_names_registered_for_autoload.shift)
                # Trigger autoload by constantizing the registered name
                Reflection.constantize(constant_name, inherit: true)
              end
            end
          end

          sig { params(constant_name: String).void }
          def register(constant_name)
            return unless enabled?

            @constant_names_registered_for_autoload << constant_name
          end

          sig do
            type_parameters(:Result)
              .params(block: T.proc.returns(T.type_parameter(:Result)))
              .returns(T.type_parameter(:Result))
          end
          def with_disabled_exits(&block)
            original_abort = Kernel.instance_method(:abort)
            original_exit = Kernel.instance_method(:exit)

            begin
              Kernel.define_method(:abort, NOOP_METHOD)
              Kernel.define_method(:exit, NOOP_METHOD)

              block.call
            ensure
              Kernel.define_method(:exit, original_exit)
              Kernel.define_method(:abort, original_abort)
            end
          end
        end
      end
    end
  end
end

# We need to do the alias-method-chain dance since Bootsnap does the same,
# and prepended modules and alias-method-chain don't play well together.
#
# So, why does Bootsnap do alias-method-chain and not prepend? Glad you asked!
# That's because RubyGems does alias-method-chain for Kernel#require and such,
# so, if Bootsnap were to do prepend, it might end up breaking RubyGems.
class Module
  alias_method(:autoload_without_tapioca, :autoload)

  def autoload(const_name, path)
    Tapioca::Runtime::Trackers::Autoload.register("#{self}::#{const_name}")
    autoload_without_tapioca(const_name, path)
  end
end

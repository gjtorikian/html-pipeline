# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module Tracker
        extend T::Sig
        extend T::Helpers

        abstract!

        class << self
          extend T::Sig

          sig { params(base: T.all(Tracker, Module)).void }
          def extended(base)
            Trackers.register_tracker(base)
            base.instance_exec do
              @enabled = true
            end
          end
        end

        sig { void }
        def disable!
          @enabled = false
        end

        def enabled?
          @enabled
        end

        def with_disabled_tracker(&block)
          original_state = @enabled
          @enabled = false

          block.call
        ensure
          @enabled = original_state
        end
      end
    end
  end
end

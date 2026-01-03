# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class Base
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { params(pipeline: Pipeline).void }
        def initialize(pipeline)
          @pipeline = pipeline
        end

        sig { params(event: NodeAdded).void }
        def dispatch(event)
          return if ignore?(event)

          case event
          when ConstNodeAdded
            on_const(event)
          when ScopeNodeAdded
            on_scope(event)
          when MethodNodeAdded
            on_method(event)
          else
            raise "Unsupported event #{event.class}"
          end
        end

        private

        sig { params(event: ConstNodeAdded).void }
        def on_const(event)
        end

        sig { params(event: ScopeNodeAdded).void }
        def on_scope(event)
        end

        sig { params(event: MethodNodeAdded).void }
        def on_method(event)
        end

        sig { params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          # Some listeners do not have to take any action on certain events. For example,
          # almost every listener should skip ForeignScopeNodeAdded events in order not to generate
          # unnecessary RBIs for foreign constants. This method should be overridden by listener
          # subclasses to skip any events that aren't relevant to them.
          false
        end
      end
    end
  end
end

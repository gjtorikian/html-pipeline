# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetEnums < Base
        extend T::Sig

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          constant = event.constant
          return unless T::Enum > event.constant # rubocop:disable Style/InvertibleUnlessCondition

          enum_block = RBI::TEnumBlock.new

          T.unsafe(constant).values.each do |enum_type|
            enum_name = enum_type.instance_variable_get(:@const_name).to_s
            enum_block << RBI::Const.new(enum_name, "new")
          end

          event.node << enum_block
        end

        sig { override.params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end

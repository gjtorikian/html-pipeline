# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module RequiredAncestor
        extend Tracker
        @required_ancestors_map = {}.compare_by_identity

        class << self
          extend T::Sig

          sig { params(requiring: T::Helpers, block: T.proc.void).void }
          def register(requiring, block)
            return unless enabled?

            ancestors = @required_ancestors_map[requiring] ||= []
            ancestors << block
          end

          sig { params(mod: Module).returns(T::Array[T.proc.void]) }
          def required_ancestors_blocks_by(mod)
            @required_ancestors_map[mod] || []
          end

          sig { params(mod: Module).returns(T::Array[T.untyped]) }
          def required_ancestors_by(mod)
            blocks = required_ancestors_blocks_by(mod)
            blocks.map do |block|
              # Common return values of `block.call` here could be a Module or a Sorbet's runtime value for T.class.
              # But in reality it could be whatever the block has that can pass Sorbet's static check. Like
              #
              # ```
              # requires_ancestor { T.class_of(Foo); nil }
              # ```
              #
              # So it's not designed to be used at runtime and it's accidental that just calling `to_s` on the above
              # common values can get us the correct value to generate type signatures. (See SorbetRequiredAncestors)
              # Therefore, the return value `block.call` should be considered unreliable and treated with caution.
              T.unsafe(block.call)
            rescue NameError
              # The ancestor required doesn't exist, let's return nil and let the compiler decide what to do.
              nil
            end
          end
        end
      end
    end
  end
end

module T
  module Helpers
    prepend(Module.new do
      def requires_ancestor(&block)
        # We can't directly call the block since the ancestor might not be loaded yet.
        # We save the block in the map and will resolve it later.
        Tapioca::Runtime::Trackers::RequiredAncestor.register(self, block)

        super
      end
    end)
  end
end

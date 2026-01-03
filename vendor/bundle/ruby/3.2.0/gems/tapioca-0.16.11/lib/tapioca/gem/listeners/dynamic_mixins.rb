# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class DynamicMixins < Base
        extend T::Sig

        include Runtime::Reflection

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          constant = event.constant
          return if constant.is_a?(Class)

          node = event.node
          mixin_compiler = Runtime::DynamicMixinCompiler.new(constant)
          mixin_compiler.compile_class_attributes(node)
          dynamic_extends, dynamic_includes = mixin_compiler.compile_mixes_in_class_methods(node)

          (dynamic_includes + dynamic_extends).each do |mod|
            name = @pipeline.name_of(mod)
            @pipeline.push_symbol(name) if name
          end
        end

        sig { override.params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end

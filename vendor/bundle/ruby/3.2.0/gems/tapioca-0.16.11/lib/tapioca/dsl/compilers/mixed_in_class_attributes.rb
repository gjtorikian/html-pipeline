# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveSupport)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::MixedInClassAttributes` generates RBI files for modules that dynamically use
      # `class_attribute` on classes.
      #
      # For example, given the following concern
      #
      # ~~~rb
      # module Taggeable
      #   extend ActiveSupport::Concern
      #
      #   included do
      #     class_attribute :tag
      #   end
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `taggeable.rbi` with the following content:
      #
      # ~~~rbi
      # # typed: strong
      #
      # module Taggeable
      #   include GeneratedInstanceMethods
      #
      #   mixes_in_class_methods GeneratedClassMethods
      #
      #   module GeneratedClassMethods
      #     def tag; end
      #     def tag=(value); end
      #     def tag?; end
      #   end
      #
      #   module GeneratedInstanceMethods
      #     def tag; end
      #     def tag=(value); end
      #     def tag?; end
      #   end
      # end
      # ~~~
      class MixedInClassAttributes < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: Module } }

        sig { override.void }
        def decorate
          mixin_compiler = Runtime::DynamicMixinCompiler.new(constant)
          return if mixin_compiler.empty_attributes?

          root.create_path(constant) do |mod|
            mixin_compiler.compile_class_attributes(mod)
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            # Select all non-anonymous modules that have overridden Module.included
            all_modules.select do |mod|
              !mod.is_a?(Class) && name_of(mod) && Runtime::Reflection.method_of(mod, :included).owner != Module
            end
          end
        end
      end
    end
  end
end

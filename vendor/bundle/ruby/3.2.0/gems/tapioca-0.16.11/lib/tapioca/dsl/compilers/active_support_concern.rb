# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveSupport::Concern)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveSupportConcern` generates RBI files for classes that both `extend`
      # `ActiveSupport::Concern` and `include` another class that extends `ActiveSupport::Concern`
      #
      # For example for the following hierarchy:
      #
      # ~~~rb
      # # concern.rb
      # module Foo
      #  extend ActiveSupport::Concern
      #  module ClassMethods; end
      # end
      #
      # module Bar
      #  extend ActiveSupport::Concern
      #  module ClassMethods; end
      #  include Foo
      # end
      #
      # class Baz
      #  include Bar
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `concern.rbi` with the following content:
      #
      # ~~~rbi
      # # typed: true
      # module Bar
      #   mixes_in_class_methods(::Foo::ClassMethods)
      # end
      # ~~~
      class ActiveSupportConcern < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: Module } }

        sig { override.void }
        def decorate
          dependencies = linearized_dependencies

          mixed_in_class_methods = dependencies
            .uniq # Deduplicate
            .filter_map do |concern| # Map to class methods module name, if exists
              "#{qualified_name_of(concern)}::ClassMethods" if concern.const_defined?(:ClassMethods, false)
            end

          return if mixed_in_class_methods.empty?

          root.create_path(constant) do |mod|
            mixed_in_class_methods.each do |mix|
              mod.create_mixes_in_class_methods(mix)
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_modules.select do |mod|
              name_of(mod) && # i.e. not anonymous
                !mod.singleton_class? &&
                ActiveSupport::Concern > mod.singleton_class &&
                has_dependencies?(mod)
            end
          end

          # Returns true when `mod` includes other concerns
          sig { params(mod: Module).returns(T::Boolean) }
          def has_dependencies?(mod) = dependencies_of(mod).any?

          sig { params(concern: Module).returns(T::Array[Module]) }
          def dependencies_of(concern)
            concern.instance_variable_get(:@_dependencies) || []
          end
        end

        private

        sig { params(concern: Module).returns(T::Array[Module]) }
        def dependencies_of(concern)
          self.class.dependencies_of(concern)
        end

        sig { params(concern: Module).returns(T::Array[Module]) }
        def linearized_dependencies(concern = constant)
          # Grab all the dependencies of the concern
          dependencies = dependencies_of(concern)

          # Flatten this concern's dependencies and all of their dependencies
          dependencies.flat_map do |dependency|
            # Linearize dependencies of the current dependency,
            # which, itself, is a concern
            linearized_dependencies(dependency) << dependency
          end
        end
      end
    end
  end
end

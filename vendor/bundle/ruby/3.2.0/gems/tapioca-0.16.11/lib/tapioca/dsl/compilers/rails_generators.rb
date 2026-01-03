# typed: strict
# frozen_string_literal: true

return unless defined?(Rails::Generators::Base)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::RailsGenerators` generates RBI files for Rails generators
      #
      # For example, with the following generator:
      #
      # ~~~rb
      # # lib/generators/sample_generator.rb
      # class ServiceGenerator < Rails::Generators::NamedBase
      #   argument :result_type, type: :string
      #
      #   class_option :skip_comments, type: :boolean, default: false
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `service_generator.rbi` with the following content:
      #
      # ~~~rbi
      # # service_generator.rbi
      # # typed: strong
      #
      # class ServiceGenerator
      #   sig { returns(::String)}
      #   def result_type; end
      #
      #   sig { returns(T::Boolean)}
      #   def skip_comments; end
      # end
      # ~~~
      class RailsGenerators < Compiler
        extend T::Sig

        BUILT_IN_MATCHER = T.let(
          /::(ActionMailbox|ActionText|ActiveRecord|Rails)::Generators/,
          Regexp,
        )

        ConstantType = type_member { { fixed: T.class_of(::Rails::Generators::Base) } }

        sig { override.void }
        def decorate
          base_class = base_class_of_constant
          arguments = constant.arguments - base_class.arguments
          class_options = constant.class_options.reject do |name, option|
            base_class.class_options[name] == option
          end

          return if arguments.empty? && class_options.empty?

          root.create_path(constant) do |klass|
            arguments.each { |argument| generate_methods_for_argument(klass, argument) }
            class_options.each { |_name, option| generate_methods_for_argument(klass, option) }
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select do |const|
              name = qualified_name_of(const)

              name &&
                !name.match?(BUILT_IN_MATCHER) &&
                ::Rails::Generators::Base > const
            end
          end
        end

        private

        sig { params(klass: RBI::Tree, argument: T.any(Thor::Argument, Thor::Option)).void }
        def generate_methods_for_argument(klass, argument)
          klass.create_method(
            argument.name,
            parameters: [],
            return_type: type_for(argument),
          )
        end

        sig { returns(T.class_of(::Rails::Generators::Base)) }
        def base_class_of_constant
          ancestor = inherited_ancestors_of(constant).find do |klass|
            qualified_name_of(klass)&.match?(BUILT_IN_MATCHER)
          end

          T.cast(ancestor, T.class_of(::Rails::Generators::Base))
        end

        sig { params(arg: T.any(Thor::Argument, Thor::Option)).returns(String) }
        def type_for(arg)
          type =
            case arg.type
            when :array then "T::Array[::String]"
            when :boolean then "T::Boolean"
            when :hash then "T::Hash[::String, ::String]"
            when :numeric then "::Numeric"
            when :string then "::String"
            else "T.untyped"
            end

          if arg.required || arg.default
            type
          else
            as_nilable_type(type)
          end
        end
      end
    end
  end
end

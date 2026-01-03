# typed: strict
# frozen_string_literal: true

require "tapioca/dsl"
require "tapioca/helpers/test/content"
require "tapioca/helpers/test/isolation"
require "tapioca/helpers/test/template"
require "tapioca/helpers/sorbet_helper"

module Tapioca
  module Helpers
    module Test
      module DslCompiler
        extend T::Sig
        extend T::Helpers

        include Isolation
        include Content
        include Template

        requires_ancestor { Kernel }

        sig { params(compiler_class: T.class_of(Tapioca::Dsl::Compiler)).void }
        def use_dsl_compiler(compiler_class)
          @context = T.let(CompilerContext.new(compiler_class), T.nilable(CompilerContext))
        end

        sig { params(compiler_classes: T.class_of(Tapioca::Dsl::Compiler)).void }
        def activate_other_dsl_compilers(*compiler_classes)
          context.activate_other_dsl_compilers(compiler_classes)
        end

        sig do
          params(
            constant_name: T.any(Symbol, String),
            compiler_options: T::Hash[Symbol, T.untyped],
          ).returns(String)
        end
        def rbi_for(constant_name, compiler_options: {})
          context.rbi_for(constant_name, compiler_options: compiler_options)
        end

        sig { returns(T::Array[String]) }
        def gathered_constants
          context.gathered_constants
        end

        sig { returns(T::Array[String]) }
        def generated_errors
          context.errors
        end

        sig { returns(CompilerContext) }
        def context
          raise "Please call `use_dsl_compiler` before" unless @context

          @context
        end

        class CompilerContext
          extend T::Sig

          include SorbetHelper

          sig { returns(T.class_of(Tapioca::Dsl::Compiler)) }
          attr_reader :compiler_class

          sig { returns(T::Array[T.class_of(Tapioca::Dsl::Compiler)]) }
          attr_reader :other_compiler_classes

          sig { params(compiler_class: T.class_of(Tapioca::Dsl::Compiler)).void }
          def initialize(compiler_class)
            @compiler_class = compiler_class
            @other_compiler_classes = T.let([], T::Array[T.class_of(Tapioca::Dsl::Compiler)])
            @pipeline = T.let(nil, T.nilable(Tapioca::Dsl::Pipeline))
            @errors = T.let([], T::Array[String])
          end

          sig { params(compiler_classes: T::Array[T.class_of(Tapioca::Dsl::Compiler)]).void }
          def activate_other_dsl_compilers(compiler_classes)
            @other_compiler_classes = compiler_classes
          end

          sig { returns(T::Array[T.class_of(Tapioca::Dsl::Compiler)]) }
          def activated_compiler_classes
            [compiler_class, *other_compiler_classes]
          end

          sig { returns(T::Array[String]) }
          def gathered_constants
            compiler_class.processable_constants.filter_map(&:name).sort
          end

          sig do
            params(
              constant_name: T.any(Symbol, String),
              compiler_options: T::Hash[Symbol, T.untyped],
            ).returns(String)
          end
          def rbi_for(constant_name, compiler_options: {})
            # Make sure this is a constant that we can handle.
            unless gathered_constants.include?(constant_name.to_s)
              raise "`#{constant_name}` is not processable by the `#{compiler_class}` compiler."
            end

            file = RBI::File.new(strictness: "strong")
            constant = Object.const_get(constant_name)

            compiler = compiler_class.new(pipeline, file.root, constant, compiler_options.transform_keys(&:to_s))
            compiler.decorate

            rbi = Tapioca::DEFAULT_RBI_FORMATTER.print_file(file)
            result = sorbet(
              "--no-config",
              "--stop-after",
              "parser",
              "-e",
              "\"#{rbi}\"",
            )

            unless result.status
              raise(SyntaxError, <<~MSG)
                Expected generated RBI file for `#{constant_name}` to not have any parsing errors.

                Got these parsing errors:

                #{result.err}
              MSG
            end

            rbi
          end

          sig { returns(T::Array[String]) }
          def errors
            pipeline.errors
          end

          private

          sig { returns(Tapioca::Dsl::Pipeline) }
          def pipeline
            @pipeline ||= Tapioca::Dsl::Pipeline.new(
              requested_constants: [],
              requested_compilers: activated_compiler_classes,
            )
          end
        end
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

module Tapioca
  module Loaders
    class Dsl < Loader
      extend T::Sig

      class << self
        extend T::Sig

        sig do
          params(
            tapioca_path: String,
            eager_load: T::Boolean,
            app_root: String,
            halt_upon_load_error: T::Boolean,
          ).void
        end
        def load_application(
          tapioca_path:,
          eager_load: true,
          app_root: ".",
          halt_upon_load_error: true
        )
          new(
            tapioca_path: tapioca_path,
            eager_load: eager_load,
            app_root: app_root,
            halt_upon_load_error: halt_upon_load_error,
          ).load
        end
      end

      sig { override.void }
      def load
        load_dsl_extensions
        load_application
        load_dsl_compilers
      end

      sig { void }
      def load_dsl_extensions_and_compilers
        load_dsl_extensions
        load_dsl_compilers
      end

      sig { void }
      def reload_custom_compilers
        # Remove all loaded custom compilers
        ::Tapioca::Dsl::Compiler.descendants.each do |compiler|
          name = compiler.name
          next unless name && @custom_compiler_paths.include?(Module.const_source_location(name)&.first)

          *parts, unqualified_name = name.split("::")

          if parts.empty?
            Object.send(:remove_const, unqualified_name)
          else
            parts.join("::").safe_constantize.send(:remove_const, unqualified_name)
          end
        end

        # Remove from $LOADED_FEATURES each workspace compiler file and then re-load
        @custom_compiler_paths.each { |path| $LOADED_FEATURES.delete(path) }
        load_custom_dsl_compilers
      end

      protected

      sig do
        params(tapioca_path: String, eager_load: T::Boolean, app_root: String, halt_upon_load_error: T::Boolean).void
      end
      def initialize(tapioca_path:, eager_load: true, app_root: ".", halt_upon_load_error: true)
        super()

        @tapioca_path = tapioca_path
        @eager_load = eager_load
        @app_root = app_root
        @halt_upon_load_error = halt_upon_load_error
        @custom_compiler_paths = T.let([], T::Array[String])
      end

      sig { void }
      def load_dsl_extensions
        say("Loading DSL extension classes... ")

        Dir.glob(["#{@tapioca_path}/extensions/**/*.rb"]).each do |extension|
          require File.expand_path(extension)
        end

        ::Gem.find_files("tapioca/dsl/extensions/*.rb").each do |extension|
          require File.expand_path(extension)
        end

        say("Done", :green)
      end

      sig { void }
      def load_dsl_compilers
        say("Loading DSL compiler classes... ")

        # Load all built-in compilers before any custom compilers
        Dir.glob("#{Tapioca::LIB_ROOT_DIR}/tapioca/dsl/compilers/*.rb").each do |compiler|
          require File.expand_path(compiler)
        end

        # Load all custom compilers exported from gems
        ::Gem.find_files("tapioca/dsl/compilers/*.rb").each do |compiler|
          require File.expand_path(compiler)
        end

        # Load all custom compilers from the project
        load_custom_dsl_compilers

        say("Done", :green)
      end

      sig { void }
      def load_application
        say("Loading Rails application... ")

        load_rails_application(
          environment_load: true,
          eager_load: @eager_load,
          app_root: @app_root,
          halt_upon_load_error: @halt_upon_load_error,
        )

        say("Done", :green)
      end

      private

      sig { void }
      def load_custom_dsl_compilers
        @custom_compiler_paths = Dir.glob([
          "#{@tapioca_path}/generators/**/*.rb", # TODO: Here for backcompat, remove later
          "#{@tapioca_path}/compilers/**/*.rb",
        ])
        @custom_compiler_paths.each { |compiler| require File.expand_path(compiler) }
      end
    end
  end
end

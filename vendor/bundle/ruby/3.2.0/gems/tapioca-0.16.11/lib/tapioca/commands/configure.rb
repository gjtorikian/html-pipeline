# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class Configure < CommandWithoutTracker
      sig do
        params(
          sorbet_config: String,
          tapioca_config: String,
          default_postrequire: String,
        ).void
      end
      def initialize(
        sorbet_config:,
        tapioca_config:,
        default_postrequire:
      )
        @sorbet_config = sorbet_config
        @tapioca_config = tapioca_config
        @default_postrequire = default_postrequire

        super()

        @installer = T.let(nil, T.nilable(Bundler::Installer))
        @spec = T.let(nil, T.nilable(Bundler::StubSpecification))
      end

      private

      sig { override.void }
      def execute
        create_sorbet_config
        create_tapioca_config
        create_post_require
        create_binstub
      end

      sig { void }
      def create_sorbet_config
        create_file(@sorbet_config, <<~CONTENT, skip: true, force: false)
          --dir
          .
          --ignore=tmp/
          --ignore=vendor/
        CONTENT
      end

      sig { void }
      def create_tapioca_config
        create_file(@tapioca_config, <<~YAML, skip: true, force: false)
          gem:
            # Add your `gem` command parameters here:
            #
            # exclude:
            # - gem_name
            # doc: true
            # workers: 5
          dsl:
            # Add your `dsl` command parameters here:
            #
            # exclude:
            # - SomeGeneratorName
            # workers: 5
        YAML
      end

      sig { void }
      def create_post_require
        create_file(@default_postrequire, <<~CONTENT, skip: true, force: false)
          # typed: true
          # frozen_string_literal: true

          # Add your extra requires here (`#{default_command(:require)}` can be used to bootstrap this list)
        CONTENT
      end

      sig { void }
      def create_binstub
        force = File.exist?(Tapioca::BINARY_FILE)

        installer.generate_bundler_executable_stubs(spec, { force: force })

        say_status(
          force ? :force : :create,
          Tapioca::BINARY_FILE,
          force ? :yellow : :green,
        )
      end

      sig { returns(Bundler::Installer) }
      def installer
        @installer ||= Bundler::Installer.new(Bundler.root, Bundler.definition)
      end

      sig { returns(T.any(Bundler::StubSpecification, ::Gem::Specification)) }
      def spec
        @spec ||= Bundler.definition.specs.find { |s| s.name == "tapioca" }
      end
    end
  end
end

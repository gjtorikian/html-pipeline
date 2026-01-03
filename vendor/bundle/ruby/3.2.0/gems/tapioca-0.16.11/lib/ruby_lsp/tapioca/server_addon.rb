# typed: false
# frozen_string_literal: true

require "tapioca/internal"
require "tapioca/dsl/compilers/url_helpers"
require "tapioca/dsl/compilers/active_record_fixtures"

module RubyLsp
  module Tapioca
    class ServerAddon < ::RubyLsp::Rails::ServerAddon
      def name
        "Tapioca"
      end

      def execute(request, params)
        case request
        when "reload_workspace_compilers"
          with_notification_wrapper("reload_workspace_compilers", "Reloading DSL compilers") do
            @loader&.reload_custom_compilers
          end
        when "load_compilers_and_extensions"
          # Load DSL extensions and compilers ahead of time, so that we don't have to pay the price of invoking
          # `Gem.find_files` on every execution, which is quite expensive
          @loader = ::Tapioca::Loaders::Dsl.new(
            tapioca_path: ::Tapioca::TAPIOCA_DIR,
            eager_load: false,
            app_root: params[:workspace_path],
            halt_upon_load_error: false,
          )
          @loader.load_dsl_extensions_and_compilers
        when "dsl"
          fork do
            with_notification_wrapper("dsl", "Generating DSL RBIs") do
              dsl(params[:constants])
            end
          end
        when "route_dsl"
          fork do
            with_notification_wrapper("route_dsl", "Generating route DSL RBIs") do
              constants = ::Tapioca::Dsl::Compilers::UrlHelpers.gather_constants
              dsl(constants.map(&:name), "--only=Tapioca::Dsl::Compilers::UrlHelpers", "ActiveSupportConcern")
            end
          end
        when "fixtures_dsl"
          fork do
            with_notification_wrapper("fixture_dsl", "Generating fixture DSL RBIs") do
              constants = ::Tapioca::Dsl::Compilers::ActiveRecordFixtures.gather_constants
              dsl(constants.map(&:name), "--only=Tapioca::Dsl::Compilers::ActiveRecordFixtures")
            end
          end
        end
      end

      private

      def with_notification_wrapper(request_name, title, &block)
        with_progress(request_name, title) do
          with_notification_error_handling(request_name, &block)
        end
      end

      def dsl(constants, *args)
        load("tapioca/cli.rb") # Reload the CLI to reset thor defaults between requests

        ::Tapioca::Cli.addon_mode!

        # Order here is important to avoid having Thor confuse arguments. Do not put an array argument at the end before
        # the list of constants
        arguments = ["dsl"]
        arguments.concat(args)
        arguments.push("--workers=1")
        arguments.concat(constants)

        ::Tapioca::Cli.start(arguments)
      end
    end
  end
end

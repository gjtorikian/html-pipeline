# typed: strict
# frozen_string_literal: true

RubyLsp::Addon.depend_on_ruby_lsp!(">= 0.23.10", "< 0.24")

begin
  # The Tapioca add-on depends on the Rails add-on to add a runtime component to the runtime server. We can allow the
  # add-on to work outside of a Rails context in the future, but that may require Tapioca spawning its own runtime
  # server
  require "ruby_lsp/ruby_lsp_rails/runner_client"
rescue LoadError
  return
end

require "zlib"
require "ruby_lsp/tapioca/run_gem_rbi_check"

module RubyLsp
  module Tapioca
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { void }
      def initialize
        super

        @global_state = T.let(nil, T.nilable(RubyLsp::GlobalState))
        @rails_runner_client = T.let(Rails::NullClient.new, RubyLsp::Rails::RunnerClient)
        @index = T.let(nil, T.nilable(RubyIndexer::Index))
        @file_checksums = T.let({}, T::Hash[String, String])
        @lockfile_diff = T.let(nil, T.nilable(String))
        @outgoing_queue = T.let(nil, T.nilable(Thread::Queue))
      end

      sig { override.params(global_state: RubyLsp::GlobalState, outgoing_queue: Thread::Queue).void }
      def activate(global_state, outgoing_queue)
        @global_state = global_state
        return unless @global_state.enabled_feature?(:tapiocaAddon)

        @index = @global_state.index
        @outgoing_queue = outgoing_queue
        Thread.new do
          # Get a handle to the Rails add-on's runtime client. The call to `rails_runner_client` will block this thread
          # until the server has finished booting, but it will not block the main LSP. This has to happen inside of a
          # thread
          addon = T.cast(::RubyLsp::Addon.get("Ruby LSP Rails", ">= 0.4.0", "< 0.5"), ::RubyLsp::Rails::Addon)
          @rails_runner_client = addon.rails_runner_client
          @outgoing_queue << Notification.window_log_message("Activating Tapioca add-on v#{version}")
          @rails_runner_client.register_server_addon(File.expand_path("server_addon.rb", __dir__))
          @rails_runner_client.delegate_notification(
            server_addon_name: "Tapioca",
            request_name: "load_compilers_and_extensions",
            workspace_path: @global_state.workspace_path,
          )

          send_usage_telemetry("activated")
          run_gem_rbi_check
        rescue IncompatibleApiError
          send_usage_telemetry("incompatible_api_error")

          # The requested version for the Rails add-on no longer matches. We need to upgrade and fix the breaking
          # changes
          @outgoing_queue << Notification.window_log_message(
            "IncompatibleApiError: Cannot activate Tapioca LSP add-on",
            type: Constant::MessageType::WARNING,
          )
        end
      end

      sig { override.void }
      def deactivate
      end

      sig { override.returns(String) }
      def name
        "Tapioca"
      end

      sig { override.returns(String) }
      def version
        "0.1.3"
      end

      sig { params(changes: T::Array[{ uri: String, type: Integer }]).void }
      def workspace_did_change_watched_files(changes)
        return unless @global_state&.enabled_feature?(:tapiocaAddon)
        return unless @rails_runner_client.connected?

        has_route_change = T.let(false, T::Boolean)
        has_fixtures_change = T.let(false, T::Boolean)
        needs_compiler_reload = T.let(false, T::Boolean)

        constants = changes.flat_map do |change|
          path = URI(change[:uri]).to_standardized_path
          next unless file_updated?(change, path)

          if File.fnmatch("**/fixtures/**/*.yml{,.erb}", path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
            has_fixtures_change = true
            next
          end

          if File.basename(path) == "routes.rb" || File.fnmatch?("**/routes/**/*.rb", path, File::FNM_PATHNAME)
            has_route_change = true
            next
          end

          next if File.fnmatch?("**/{test,spec,features}/**/*", path, File::FNM_PATHNAME | File::FNM_EXTGLOB)

          if File.fnmatch?("**/tapioca/**/compilers/**/*.rb", path, File::FNM_PATHNAME)
            needs_compiler_reload = true
            next
          end

          entries = T.must(@index).entries_for(change[:uri])
          next unless entries

          entries.filter_map do |entry|
            entry.name if entry.class == RubyIndexer::Entry::Class || entry.class == RubyIndexer::Entry::Module
          end
        end.compact

        return if constants.empty? && !has_route_change && !has_fixtures_change && !needs_compiler_reload

        @rails_runner_client.trigger_reload

        if needs_compiler_reload
          @rails_runner_client.delegate_notification(
            server_addon_name: "Tapioca",
            request_name: "reload_workspace_compilers",
            workspace_path: @global_state.workspace_path,
          )
        end

        if has_route_change
          send_usage_telemetry("route_dsl")
          @rails_runner_client.delegate_notification(server_addon_name: "Tapioca", request_name: "route_dsl")
        end

        if has_fixtures_change
          send_usage_telemetry("fixtures_dsl")
          @rails_runner_client.delegate_notification(server_addon_name: "Tapioca", request_name: "fixtures_dsl")
        end

        if constants.any?
          send_usage_telemetry("dsl")
          @rails_runner_client.delegate_notification(
            server_addon_name: "Tapioca",
            request_name: "dsl",
            constants: constants,
          )
        end
      end

      private

      sig { params(feature_name: String).void }
      def send_usage_telemetry(feature_name)
        return unless @outgoing_queue && @global_state

        # Telemetry is not captured by default even if events are produced by the server
        # See https://github.com/Shopify/ruby-lsp/tree/main/vscode#telemetry
        @outgoing_queue << Notification.telemetry({
          eventName: "tapioca_addon.feature_usage",
          type: "data",
          data: {
            type: "counter",
            attributes: {
              label: feature_name,
              machineId: @global_state.telemetry_machine_id,
            },
          },
        })
      end

      sig { params(change: T::Hash[Symbol, T.untyped], path: String).returns(T::Boolean) }
      def file_updated?(change, path)
        case change[:type]
        when Constant::FileChangeType::CREATED
          @file_checksums[path] = Zlib.crc32(File.read(path)).to_s
          return true
        when Constant::FileChangeType::CHANGED
          current_checksum = Zlib.crc32(File.read(path)).to_s
          if @file_checksums[path] == current_checksum
            T.must(@outgoing_queue) << Notification.window_log_message(
              "File has not changed. Skipping #{path}",
              type: Constant::MessageType::INFO,
            )
          else
            @file_checksums[path] = current_checksum
            return true
          end
        when Constant::FileChangeType::DELETED
          @file_checksums.delete(path)
        else
          T.must(@outgoing_queue) << Notification.window_log_message(
            "Unexpected file change type: #{change[:type]}",
            type: Constant::MessageType::WARNING,
          )
        end

        false
      end

      sig { void }
      def run_gem_rbi_check
        gem_rbi_check = RunGemRbiCheck.new(T.must(@global_state).workspace_path)
        gem_rbi_check.run

        T.must(@outgoing_queue) << Notification.window_log_message(
          gem_rbi_check.stdout,
        ) unless gem_rbi_check.stdout.empty?
        T.must(@outgoing_queue) << Notification.window_log_message(
          gem_rbi_check.stderr,
          type: Constant::MessageType::WARNING,
        ) unless gem_rbi_check.stderr.empty?
      end
    end
  end
end

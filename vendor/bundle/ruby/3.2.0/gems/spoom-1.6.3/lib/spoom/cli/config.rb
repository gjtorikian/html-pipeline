# typed: true
# frozen_string_literal: true

require_relative "../file_tree"
require_relative "../sorbet/config"

module Spoom
  module Cli
    class Config < Thor
      include Helper

      default_task :show

      desc "show", "Show Sorbet config"
      def show
        context = context_requiring_sorbet!
        config = context.sorbet_config
        config_path = Pathname.new("#{exec_path}/#{Spoom::Sorbet::CONFIG_PATH}").cleanpath

        say("Found Sorbet config at `#{config_path}`.")

        say("\nPaths typechecked:")
        if config.paths.empty?
          say(" * (default: .)")
        else
          config.paths.each do |path|
            say(" * #{path}")
          end
        end

        say("\nPaths ignored:")
        if config.ignore.empty?
          say(" * (default: none)")
        else
          config.ignore.each do |path|
            say(" * #{path}")
          end
        end

        say("\nAllowed extensions:")
        if config.allowed_extensions.empty?
          say(" * .rb (default)")
          say(" * .rbi (default)")
        else
          config.allowed_extensions.each do |ext|
            say(" * #{ext}")
          end
        end
      end
    end
  end
end

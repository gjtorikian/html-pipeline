# typed: true
# frozen_string_literal: true

require "thor"

require_relative "cli/helper"
require_relative "cli/deadcode"
require_relative "cli/srb"

module Spoom
  module Cli
    class Main < Thor
      include Helper

      class_option :color, type: :boolean, default: true, desc: "Use colors"
      class_option :path, type: :string, default: ".", aliases: :p, desc: "Run spoom in a specific path"

      map T.unsafe(["--version", "-v"] => :__print_version)

      desc "srb", "Sorbet related commands"
      subcommand "srb", Spoom::Cli::Srb::Main

      desc "bump", "Bump Sorbet sigils from `false` to `true` when no errors"
      option :from,
        type: :string,
        default: Spoom::Sorbet::Sigils::STRICTNESS_FALSE,
        desc: "Change only files from this strictness"
      option :to,
        type: :string,
        default: Spoom::Sorbet::Sigils::STRICTNESS_TRUE,
        desc: "Change files to this strictness"
      option :force,
        type: :boolean,
        default: false,
        aliases: :f,
        desc: "Change strictness without type checking"
      option :sorbet, type: :string, desc: "Path to custom Sorbet bin"
      option :dry,
        type: :boolean,
        default: false,
        aliases: :d,
        desc: "Only display what would happen, do not actually change sigils"
      option :only,
        type: :string,
        default: nil,
        aliases: :o,
        desc: "Only change specified list (one file by line)"
      option :suggest_bump_command,
        type: :string,
        desc: "Command to suggest if files can be bumped"
      option :count_errors,
        type: :boolean,
        default: false,
        desc: "Count the number of errors if all files were bumped"
      option :sorbet_options, type: :string, default: "", desc: "Pass options to Sorbet"
      #: (?String directory) -> void
      def bump(directory = ".")
        say_warning("This command is deprecated. Please use `spoom srb bump` instead.")

        invoke(Cli::Srb::Bump, :bump, [directory], options)
      end

      desc "coverage", "Collect metrics related to Sorbet coverage"
      def coverage(*args)
        say_warning("This command is deprecated. Please use `spoom srb coverage` instead.")

        invoke(Cli::Srb::Coverage, args, options)
      end

      desc "deadcode", "Analyze code to find deadcode"
      subcommand "deadcode", Spoom::Cli::Deadcode

      desc "lsp", "Send LSP requests to Sorbet"
      def lsp(*args)
        say_warning("This command is deprecated. Please use `spoom srb lsp` instead.")

        invoke(Cli::Srb::LSP, args, options)
      end

      SORT_CODE = "code"
      SORT_LOC = "loc"
      SORT_ENUM = [SORT_CODE, SORT_LOC]

      desc "tc", "Run Sorbet and parses its output"
      option :limit, type: :numeric, aliases: :l, desc: "Limit displayed errors"
      option :code, type: :numeric, aliases: :c, desc: "Filter displayed errors by code"
      option :sort, type: :string, aliases: :s, desc: "Sort errors", enum: SORT_ENUM, default: SORT_LOC
      option :format, type: :string, aliases: :f, desc: "Format line output"
      option :uniq, type: :boolean, aliases: :u, desc: "Remove duplicated lines"
      option :count, type: :boolean, default: true, desc: "Show errors count"
      option :sorbet, type: :string, desc: "Path to custom Sorbet bin"
      option :sorbet_options, type: :string, default: "", desc: "Pass options to Sorbet"
      def tc(*paths_to_select)
        say_warning("This command is deprecated. Please use `spoom srb tc` instead.")

        invoke(Cli::Srb::Tc, :tc, paths_to_select, options)
      end

      desc "--version", "Show version"
      def __print_version
        puts "Spoom v#{Spoom::VERSION}"
      end

      # Utils

      class << self
        def exit_on_failure?
          true
        end
      end
    end
  end
end

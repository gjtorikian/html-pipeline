# typed: true
# frozen_string_literal: true

require "find"
require "open3"

module Spoom
  module Cli
    module Srb
      class Bump < Thor
        include Helper

        default_task :bump

        desc "bump DIRECTORY", "Change Sorbet sigils from one strictness to another when no errors"
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
          context = context_requiring_sorbet!
          from = options[:from]
          to = options[:to]
          force = options[:force]
          dry = options[:dry]
          only = options[:only]
          cmd = options[:suggest_bump_command]
          directory = File.expand_path(directory)
          exec_path = File.expand_path(self.exec_path)

          unless Sorbet::Sigils.valid_strictness?(from)
            say_error("Invalid strictness `#{from}` for option `--from`")
            exit(1)
          end

          unless Sorbet::Sigils.valid_strictness?(to)
            say_error("Invalid strictness `#{to}` for option `--to`")
            exit(1)
          end

          if options[:count_errors] && !dry
            say_error("`--count-errors` can only be used with `--dry`")
            exit(1)
          end

          say("Checking files...")

          files_to_bump = context.srb_files_with_strictness(from, include_rbis: false)
            .map { |file| File.expand_path(file, context.absolute_path) }
            .select { |file| file.start_with?(directory) }

          if only
            list = File.read(only).lines.map { |file| File.expand_path(file.strip) }
            files_to_bump.select! { |file| list.include?(File.expand_path(file)) }
          end

          say("\n")

          if files_to_bump.empty?
            say("No files to bump from `#{from}` to `#{to}`")
            exit(0)
          end

          Sorbet::Sigils.change_sigil_in_files(files_to_bump, to)

          if force
            print_changes(files_to_bump, command: cmd, from: from, to: to, dry: dry, path: exec_path)
            undo_changes(files_to_bump, from) if dry
            exit(files_to_bump.empty?)
          end

          error_url_base = Spoom::Sorbet::Errors::DEFAULT_ERROR_URL_BASE
          result = begin
            T.unsafe(context).srb_tc(
              *options[:sorbet_options].split(" "),
              "--error-url-base=#{error_url_base}",
              capture_err: true,
              sorbet_bin: options[:sorbet],
            )
          rescue Spoom::Sorbet::Error::Segfault => error
            say_error(<<~ERR, status: nil)
              !!! Sorbet exited with code #{Spoom::Sorbet::SEGFAULT_CODE} - SEGFAULT !!!

              This is most likely related to a bug in Sorbet.
              It means one of the file bumped to `typed: #{to}` made Sorbet crash.
              Run `spoom bump -f` locally followed by `bundle exec srb tc` to investigate the problem.
            ERR
            undo_changes(files_to_bump, from)
            exit(error.result.exit_code)
          rescue Spoom::Sorbet::Error::Killed => error
            say_error(<<~ERR, status: nil)
              !!! Sorbet exited with code #{Spoom::Sorbet::KILLED_CODE} - KILLED !!!

              It means Sorbet was killed while executing. Changes to files have not been applied.
              Re-run `spoom bump` to try again.
            ERR
            undo_changes(files_to_bump, from)
            exit(error.result.exit_code)
          end

          if result.status
            print_changes(files_to_bump, command: cmd, from: from, to: to, dry: dry, path: exec_path)
            undo_changes(files_to_bump, from) if dry
            exit(files_to_bump.empty?)
          end

          unless result.exit_code == 100
            # Sorbet will return exit code 100 if there are type checking errors.
            # If Sorbet returned something else, it means it didn't terminate normally.
            say_error(result.err, status: nil, nl: false)
            undo_changes(files_to_bump, from)
            exit(1)
          end

          errors = Sorbet::Errors::Parser.parse_string(result.err, error_url_base: error_url_base)

          all_files = errors.flat_map do |err|
            [err.file, *err.files_from_error_sections]
          end

          files_with_errors = all_files.map do |file|
            path = File.expand_path(file)
            next unless path.start_with?(directory)
            next unless File.file?(path)
            next unless files_to_bump.include?(path)

            path
          end.compact.uniq

          undo_changes(files_with_errors, from)

          say("Found #{errors.length} type checking error#{"s" if errors.length > 1}") if options[:count_errors]

          files_changed = files_to_bump - files_with_errors
          print_changes(files_changed, command: cmd, from: from, to: to, dry: dry, path: exec_path)
          undo_changes(files_to_bump, from) if dry
          exit(files_changed.empty?)
        end

        no_commands do
          def print_changes(files, command:, from: "false", to: "true", dry: false, path: File.expand_path("."))
            files_count = files.size
            if files_count.zero?
              say("No files to bump from `#{from}` to `#{to}`")
              return
            end
            message = StringIO.new
            message << (dry ? "Can bump" : "Bumped")
            message << " `#{files_count}` file#{"s" if files_count > 1}"
            message << " from `#{from}` to `#{to}`:"
            say(message.string)
            files.each do |file|
              file_path = Pathname.new(file).relative_path_from(path)
              say(" + #{file_path}")
            end
            if dry && command
              say("\nRun `#{command}` to bump #{files_count > 1 ? "them" : "it"}")
            elsif dry
              say("\nRun `spoom srb bump --from #{from} --to #{to}` locally then `commit the changes` and `push them`")
            end
          end

          def undo_changes(files, from_strictness)
            Sorbet::Sigils.change_sigil_in_files(files, from_strictness)
          end
        end
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

require "fileutils"
require "pathname"
require "stringio"

module Spoom
  module Cli
    module Helper
      extend T::Helpers

      include Colorize

      requires_ancestor { Thor }

      # Print `message` on `$stdout`
      #: (String message) -> void
      def say(message)
        buffer = StringIO.new
        buffer << highlight(message)
        buffer << "\n" unless message.end_with?("\n")

        $stdout.print(buffer.string)
        $stdout.flush
      end

      # Print `message` on `$stderr`
      #
      # The message is prefixed by a status (default: `Error`).
      #: (String message, ?status: String?, ?nl: bool) -> void
      def say_error(message, status: "Error", nl: true)
        buffer = StringIO.new
        buffer << "#{red(status)}: " if status
        buffer << highlight(message)
        buffer << "\n" if nl && !message.end_with?("\n")

        $stderr.print(buffer.string)
        $stderr.flush
      end

      # Print `message` on `$stderr`
      #
      # The message is prefixed by a status (default: `Warning`).
      #: (String message, ?status: String?, ?nl: bool) -> void
      def say_warning(message, status: "Warning", nl: true)
        buffer = StringIO.new
        buffer << "#{yellow(status)}: " if status
        buffer << highlight(message)
        buffer << "\n" if nl && !message.end_with?("\n")

        $stderr.print(buffer.string)
        $stderr.flush
      end

      # Returns the context at `--path` (by default the current working directory)
      #: -> Context
      def context
        @context ||= Context.new(exec_path) #: Context?
      end

      # Raise if `spoom` is not ran inside a context with a `sorbet/config` file
      #: -> Context
      def context_requiring_sorbet!
        context = self.context
        unless context.has_sorbet_config?
          say_error(
            "not in a Sorbet project (`#{Spoom::Sorbet::CONFIG_PATH}` not found)\n\n" \
              "When running spoom from another path than the project's root, " \
              "use `--path PATH` to specify the path to the root.",
          )
          Kernel.exit(1)
        end
        context
      end

      # Return the path specified through `--path`
      #: -> String
      def exec_path
        options[:path]
      end

      # Collect files from `paths`, defaulting to `exec_path`
      #: (Array[String] paths, ?include_rbi_files: bool) -> Array[String]
      def collect_files(paths, include_rbi_files: false)
        paths << exec_path if paths.empty?

        files = paths.flat_map do |path|
          if File.file?(path)
            path
          else
            exts = ["rb"]
            exts << "rbi" if include_rbi_files
            Dir.glob("#{path}/**/*.{#{exts.join(",")}}")
          end
        end

        if files.empty?
          say_error("No files found")
          exit(1)
        end

        files
      end

      # Colors

      # Color used to highlight expressions in backticks
      HIGHLIGHT_COLOR = Spoom::Color::BLUE #: Spoom::Color

      # Is the `--color` option true?
      #: -> bool
      def color?
        options[:color]
      end

      #: (String string) -> String
      def highlight(string)
        return string unless color?

        res = StringIO.new
        word = StringIO.new
        in_ticks = false #: bool
        string.chars.each do |c|
          if c == "`" && !in_ticks
            in_ticks = true
          elsif c == "`" && in_ticks
            in_ticks = false
            res << colorize(word.string, HIGHLIGHT_COLOR)
            word = StringIO.new
          elsif in_ticks
            word << c
          else
            res << c
          end
        end
        res.string
      end

      # Colorize a string if `color?`
      #: (String string, *Color color) -> String
      def colorize(string, *color)
        return string unless color?

        T.unsafe(self).set_color(string, *color)
      end

      #: (String string) -> String
      def blue(string)
        colorize(string, Color::BLUE)
      end

      #: (String string) -> String
      def cyan(string)
        colorize(string, Color::CYAN)
      end

      #: (String string) -> String
      def gray(string)
        colorize(string, Color::LIGHT_BLACK)
      end

      #: (String string) -> String
      def green(string)
        colorize(string, Color::GREEN)
      end

      #: (String string) -> String
      def red(string)
        colorize(string, Color::RED)
      end

      #: (String string) -> String
      def yellow(string)
        colorize(string, Color::YELLOW)
      end
    end
  end
end

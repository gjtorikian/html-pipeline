# typed: strict
# frozen_string_literal: true

require "stringio"

module Spoom
  class Printer
    include Colorize

    #: (IO | StringIO)
    attr_accessor :out

    #: (?out: (IO | StringIO), ?colors: bool, ?indent_level: Integer) -> void
    def initialize(out: $stdout, colors: true, indent_level: 0)
      @out = out
      @colors = colors
      @indent_level = indent_level
    end

    # Increase indent level
    #: -> void
    def indent
      @indent_level += 2
    end

    # Decrease indent level
    #: -> void
    def dedent
      @indent_level -= 2
    end

    # Print `string` into `out`
    #: (String? string) -> void
    def print(string)
      return unless string

      @out.print(string)
    end

    # Print `string` colored with `color` into `out`
    #
    # Does not use colors unless `@colors`.
    #: (String? string, *Color color) -> void
    def print_colored(string, *color)
      return unless string

      string = T.unsafe(self).colorize(string, *color)
      @out.print(string)
    end

    # Print a new line into `out`
    #: -> void
    def printn
      print("\n")
    end

    # Print `string` with indent and newline
    #: (String? string) -> void
    def printl(string)
      return unless string

      printt
      print(string)
      printn
    end

    # Print an indent space into `out`
    #: -> void
    def printt
      print(" " * @indent_level)
    end

    # Colorize `string` with color if `@colors`
    #: (String string, *Spoom::Color color) -> String
    def colorize(string, *color)
      return string unless @colors

      T.unsafe(self).set_color(string, *color)
    end
  end
end

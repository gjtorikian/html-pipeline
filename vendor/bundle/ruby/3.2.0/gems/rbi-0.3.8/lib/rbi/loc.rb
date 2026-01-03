# typed: strict
# frozen_string_literal: true

module RBI
  class Loc
    class << self
      #: (String file, Prism::Location prism_location) -> Loc
      def from_prism(file, prism_location)
        new(
          file: file,
          begin_line: prism_location.start_line,
          end_line: prism_location.end_line,
          begin_column: prism_location.start_column,
          end_column: prism_location.end_column,
        )
      end
    end

    #: String?
    attr_reader :file

    #: Integer?
    attr_reader :begin_line, :end_line, :begin_column, :end_column

    #: (
    #|   ?file: String?,
    #|   ?begin_line: Integer?,
    #|   ?end_line: Integer?,
    #|   ?begin_column: Integer?,
    #|   ?end_column: Integer?
    #| ) -> void
    def initialize(file: nil, begin_line: nil, end_line: nil, begin_column: nil, end_column: nil)
      @file = file
      @begin_line = begin_line
      @end_line = end_line
      @begin_column = begin_column
      @end_column = end_column
    end

    #: (Loc) -> Loc
    def join(other)
      Loc.new(
        file: file,
        begin_line: begin_line,
        begin_column: begin_column,
        end_line: other.end_line,
        end_column: other.end_column,
      )
    end

    #: -> String
    def to_s
      if end_line && end_column
        "#{file}:#{begin_line}:#{begin_column}-#{end_line}:#{end_column}"
      else
        "#{file}:#{begin_line}:#{begin_column}"
      end
    end

    #: -> String?
    def source
      file = self.file
      return unless file
      return unless ::File.file?(file)

      return ::File.read(file) unless begin_line && end_line

      string = String.new
      ::File.foreach(file).with_index do |line, line_number|
        string << line if (line_number + 1).between?(begin_line, end_line)
      end
      string
    end
  end
end

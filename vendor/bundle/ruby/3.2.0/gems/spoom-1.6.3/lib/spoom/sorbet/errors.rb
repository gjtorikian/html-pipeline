# typed: strict
# frozen_string_literal: true

require "rexml/document"

module Spoom
  module Sorbet
    module Errors
      DEFAULT_ERROR_URL_BASE = "https://srb.help/"

      class << self
        #: (Array[Error] errors) -> Array[Error]
        def sort_errors_by_code(errors)
          errors.sort_by { |e| [e.code, e.file, e.line, e.message] }
        end

        #: (Array[Error]) -> REXML::Document
        def to_junit_xml(errors)
          testsuite_element = REXML::Element.new("testsuite")
          testsuite_element.add_attributes(
            "name" => "Sorbet",
            "failures" => errors.size,
          )

          if errors.empty?
            # Avoid creating an empty report when there are no errors so that
            # reporting tools know that the type checking ran successfully.
            testcase_element = testsuite_element.add_element("testcase")
            testcase_element.add_attributes(
              "name" => "Typecheck",
              "tests" => 1,
            )
          else
            errors.each do |error|
              testsuite_element.add_element(error.to_junit_xml_element)
            end
          end

          doc = REXML::Document.new
          doc << REXML::XMLDecl.new
          doc.add_element(testsuite_element)

          doc
        end
      end
      # Parse errors from Sorbet output
      class Parser
        class ParseError < Spoom::Error; end

        HEADER = [
          "👋 Hey there! Heads up that this is not a release build of sorbet.",
          "Release builds are faster and more well-supported by the Sorbet team.",
          "Check out the README to learn how to build Sorbet in release mode.",
          "To forcibly silence this error, either pass --silence-dev-message,",
          "or set SORBET_SILENCE_DEV_MESSAGE=1 in your shell environment.",
        ] #: Array[String]

        class << self
          #: (String output, ?error_url_base: String) -> Array[Error]
          def parse_string(output, error_url_base: DEFAULT_ERROR_URL_BASE)
            parser = Spoom::Sorbet::Errors::Parser.new(error_url_base: error_url_base)
            parser.parse(output)
          end
        end

        #: (?error_url_base: String) -> void
        def initialize(error_url_base: DEFAULT_ERROR_URL_BASE)
          @errors = [] #: Array[Error]
          @error_line_match_regex = error_line_match_regexp(error_url_base) #: Regexp
          @current_error = nil #: Error?
        end

        #: (String output) -> Array[Error]
        def parse(output)
          output.each_line do |line|
            break if /^No errors! Great job\./.match?(line)
            break if /^Errors: /.match?(line)
            next if HEADER.include?(line.strip)

            next if line == "\n"

            if (error = match_error_line(line))
              close_error if @current_error
              open_error(error)
              next
            end

            append_error(line) if @current_error
          end
          close_error if @current_error
          @errors
        end

        private

        #: (String error_url_base) -> Regexp
        def error_line_match_regexp(error_url_base)
          url = Regexp.escape(error_url_base)
          %r{
            ^         # match beginning of line
            (\S[^:]*) # capture filename as something that starts with a non-space character
                      # followed by anything that is not a colon character
            :         # match the filename - line number separator
            (\d+)     # capture the line number
            :\s       # match the line number - error message separator
            (.*)      # capture the error message
            \s#{url}  # match the error code url prefix
            (\d+)     # capture the error code
            $         # match end of line
          }x
        end

        #: (String line) -> Error?
        def match_error_line(line)
          match = line.match(@error_line_match_regex)
          return unless match

          file, line, message, code = match.captures
          Error.new(file, line&.to_i, message, code&.to_i)
        end

        #: (Error error) -> void
        def open_error(error)
          raise ParseError, "Error: Already parsing an error!" if @current_error

          @current_error = error
        end

        #: -> void
        def close_error
          raise ParseError, "Error: Not already parsing an error!" unless @current_error

          @errors << @current_error
          @current_error = nil
        end

        #: (String line) -> void
        def append_error(line)
          raise ParseError, "Error: Not already parsing an error!" unless @current_error

          filepath_match = line.match(/^    (.*?):\d+/)
          if filepath_match && filepath_match[1]
            @current_error.files_from_error_sections << T.must(filepath_match[1])
          end
          @current_error.more << line
        end
      end

      class Error
        include Comparable

        #: String?
        attr_reader :file, :message

        #: Integer?
        attr_reader :line, :code

        #: Array[String]
        attr_reader :more

        # Other files associated with the error
        #: Set[String]
        attr_reader :files_from_error_sections

        #: (String? file, Integer? line, String? message, Integer? code, ?Array[String] more) -> void
        def initialize(file, line, message, code, more = [])
          @file = file
          @line = line
          @message = message
          @code = code
          @more = more
          @files_from_error_sections = Set.new #: Set[String]
        end

        # By default errors are sorted by location
        #: (untyped other) -> Integer
        def <=>(other)
          return 0 unless other.is_a?(Error)

          [file, line, code, message] <=> [other.file, other.line, other.code, other.message]
        end

        #: -> String
        def to_s
          "#{file}:#{line}: #{message} (#{code})"
        end

        #: -> REXML::Element
        def to_junit_xml_element
          testcase_element = REXML::Element.new("testcase")
          # Unlike traditional test suites, we can't report all tests
          # regardless of outcome; we only have errors to report. As a
          # result we reinterpret the definitions of the test properties
          # bit: the error message becomes the test name and the full error
          # info gets plugged into the failure body along with file/line
          # information (displayed in Jenkins as the "Stacktrace" for the
          # error).
          testcase_element.add_attributes(
            "name" => message,
            "file" => file,
            "line" => line,
          )
          failure_element = testcase_element.add_element("failure")
          failure_element.add_attributes(
            "type" => code,
          )
          explanation_text = [
            "In file #{file}:\n",
            *more,
          ].join.chomp
          # Use CDATA so that parsers know the whitespace is significant.
          failure_element.add(REXML::CData.new(explanation_text))

          testcase_element
        end
      end
    end
  end
end

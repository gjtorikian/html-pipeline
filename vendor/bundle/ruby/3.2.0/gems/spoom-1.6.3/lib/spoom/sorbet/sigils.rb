# typed: strict
# frozen_string_literal: true

# The term "sigil" refers to the magic comment at the top of the file that has the form `# typed: <strictness>`,
# where "strictness" represents the level at which Sorbet will report errors
# See https://sorbet.org/docs/static for a more complete explanation
module Spoom
  module Sorbet
    module Sigils
      STRICTNESS_IGNORE = "ignore"
      STRICTNESS_FALSE = "false"
      STRICTNESS_TRUE = "true"
      STRICTNESS_STRICT = "strict"
      STRICTNESS_STRONG = "strong"
      STRICTNESS_INTERNAL = "__STDLIB_INTERNAL"

      VALID_STRICTNESS = [
        STRICTNESS_IGNORE,
        STRICTNESS_FALSE,
        STRICTNESS_TRUE,
        STRICTNESS_STRICT,
        STRICTNESS_STRONG,
        STRICTNESS_INTERNAL,
      ].freeze #: Array[String]

      SIGIL_REGEXP = /^#[[:blank:]]*typed:[[:blank:]]*(\S*)/ #: Regexp

      class << self
        # returns the full sigil comment string for the passed strictness
        #: (String strictness) -> String
        def sigil_string(strictness)
          "# typed: #{strictness}"
        end

        # returns true if the passed string is a valid strictness (else false)
        #: (String strictness) -> bool
        def valid_strictness?(strictness)
          VALID_STRICTNESS.include?(strictness.strip)
        end

        # returns the strictness of a sigil in the passed file content string (nil if no sigil)
        #: (String content) -> String?
        def strictness_in_content(content)
          SIGIL_REGEXP.match(content)&.[](1)
        end

        # returns a string which is the passed content but with the sigil updated to a new strictness
        #: (String content, String new_strictness) -> String
        def update_sigil(content, new_strictness)
          content.sub(SIGIL_REGEXP, sigil_string(new_strictness))
        end

        # returns a string containing the strictness of a sigil in a file at the passed path
        # * returns nil if no sigil
        #: ((String | Pathname) path) -> String?
        def file_strictness(path)
          return unless File.file?(path)

          content = File.read(path, encoding: Encoding::ASCII_8BIT)
          strictness_in_content(content)
        end

        # changes the sigil in the file at the passed path to the specified new strictness
        #: ((String | Pathname) path, String new_strictness) -> bool
        def change_sigil_in_file(path, new_strictness)
          content = File.read(path, encoding: Encoding::ASCII_8BIT)
          new_content = update_sigil(content, new_strictness)

          File.write(path, new_content, encoding: Encoding::ASCII_8BIT)

          strictness_in_content(new_content) == new_strictness
        end

        # changes the sigil to have a new strictness in a list of files
        #: (Array[String] path_list, String new_strictness) -> Array[String]
        def change_sigil_in_files(path_list, new_strictness)
          path_list.filter do |path|
            change_sigil_in_file(path, new_strictness)
          end
        end
      end
    end
  end
end

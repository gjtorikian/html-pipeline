# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Checks that the Sorbet sigil comes as the first magic comment in the file, after the encoding comment if any.
      #
      # The expected order for magic comments is: (en)?coding, typed, warn_indent then frozen_string_literal.
      #
      # The ordering is for consistency only, except for the encoding comment which must be first, if present.
      #
      # For example, the following bad ordering:
      #
      # ```ruby
      # # frozen_string_literal: true
      # # typed: true
      # class Foo; end
      # ```
      #
      # Will be corrected as:
      #
      # ```ruby
      # # typed: true
      # # frozen_string_literal: true
      # class Foo; end
      # ```
      #
      # Only `(en)?coding`, `typed`, `warn_indent` and `frozen_string_literal` magic comments are considered,
      # other comments or magic comments are left in the same place.
      class EnforceSigilOrder < ValidSigil
        include RangeHelp

        def on_new_investigation
          return if processed_source.tokens.empty?

          tokens = extract_magic_comments(processed_source)
          return if tokens.empty?

          check_magic_comments_order(tokens)
        end

        protected

        CODING_REGEX = /#\s+(en)?coding:(?:\s+([\w]+))?/
        INDENT_REGEX = /#\s+warn_indent:(?:\s+([\w]+))?/
        FROZEN_REGEX = /#\s+frozen_string_literal:(?:\s+([\w]+))?/

        PREFERRED_ORDER = {
          CODING_REGEX => "encoding",
          SIGIL_REGEX => "typed",
          INDENT_REGEX => "warn_indent",
          FROZEN_REGEX => "frozen_string_literal",
        }.freeze

        MAGIC_REGEX = Regexp.union(*PREFERRED_ORDER.keys)

        # extraction

        # Get all the tokens in `processed_source` that match `MAGIC_REGEX`
        def extract_magic_comments(processed_source)
          processed_source.tokens
            .take_while { |token| token.type == :tCOMMENT }
            .select { |token| MAGIC_REGEX.match?(token.text) }
        end

        # checks

        def check_magic_comments_order(tokens)
          # Get the current magic comments order
          order = tokens.map do |token|
            PREFERRED_ORDER.keys.find { |re| re.match?(token.text) }
          end.compact.uniq

          # Get the expected magic comments order based on the one used in the actual source
          expected = PREFERRED_ORDER.keys.select do |re|
            tokens.any? { |token| re.match?(token.text) }
          end.uniq

          if order != expected
            tokens.each do |token|
              add_offense(
                token.pos,
                message: "Magic comments should be in the following order: #{PREFERRED_ORDER.values.join(", ")}.",
              ) do |corrector|
                autocorrect(corrector)
              end
            end
          end
        end

        def autocorrect(corrector)
          tokens = extract_magic_comments(processed_source)

          # Get the magic comments tokens in their expected order
          expected = PREFERRED_ORDER.keys.map do |re|
            tokens.select { |token| re.match?(token.text) }
          end.flatten

          tokens.each_with_index do |token, index|
            corrector.replace(token.pos, expected[index].text)
          end

          # Remove blank lines between the magic comments
          lines = tokens.map(&:line).to_set
          (lines.min...lines.max).each do |line|
            next if lines.include?(line)
            next unless processed_source[line - 1].empty?

            corrector.remove(source_range(processed_source.buffer, line, 0))
          end
        end
      end
    end
  end
end

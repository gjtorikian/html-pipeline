# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks that there is only one Sorbet sigil in a given file
      #
      # For example, the following class with two sigils
      #
      # ```ruby
      # # typed: true
      # # typed: true
      # # frozen_string_literal: true
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
      # Other comments or magic comments are left in place.
      class EnforceSingleSigil < ValidSigil
        include RangeHelp

        def on_new_investigation
          return if processed_source.tokens.empty?

          sigils = extract_all_sigils(processed_source)
          return if sigils.empty?

          sigils[1..sigils.size].each do |token|
            add_offense(token.pos, message: "Files must only contain one sigil") do |corrector|
              autocorrect(corrector)
            end
          end
        end

        protected

        def extract_all_sigils(processed_source)
          processed_source.tokens
            .take_while { |token| token.type == :tCOMMENT }
            .find_all { |token| SIGIL_REGEX.match?(token.text) }
        end

        def autocorrect(corrector)
          sigils = extract_all_sigils(processed_source)
          return if sigils.empty?

          # The first sigil encountered represents the "real" strictness so remove any below
          sigils[1..sigils.size].each do |token|
            corrector.remove(
              source_range(processed_source.buffer, token.line, 0..token.pos.last_column),
            )
          end
        end
      end
    end
  end
end

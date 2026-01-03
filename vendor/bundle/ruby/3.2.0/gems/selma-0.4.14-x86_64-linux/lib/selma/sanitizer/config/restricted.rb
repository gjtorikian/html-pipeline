# frozen_string_literal: true

module Selma
  class Sanitizer
    module Config
      RESTRICTED = freeze_config(
        elements: ["b", "em", "i", "strong", "u"],

        whitespace_elements: DEFAULT[:whitespace_elements],
      )
    end
  end
end

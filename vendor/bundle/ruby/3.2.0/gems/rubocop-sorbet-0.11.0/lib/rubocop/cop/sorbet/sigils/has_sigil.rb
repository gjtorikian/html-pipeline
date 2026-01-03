# frozen_string_literal: true

require "rubocop"
require_relative "valid_sigil"

module RuboCop
  module Cop
    module Sorbet
      # Makes the Sorbet typed sigil mandatory in all files.
      #
      # Options:
      #
      # * `SuggestedStrictness`: Sorbet strictness level suggested in offense messages (default: 'false')
      # * `MinimumStrictness`: If set, make offense if the strictness level in the file is below this one
      #
      # If a `SuggestedStrictness` level is specified, it will be used in autocorrect.
      # If a `MinimumStrictness` level is specified, it will be used in offense messages and autocorrect.
      class HasSigil < ValidSigil
        def require_sigil_on_all_files?
          true
        end
      end
    end
  end
end

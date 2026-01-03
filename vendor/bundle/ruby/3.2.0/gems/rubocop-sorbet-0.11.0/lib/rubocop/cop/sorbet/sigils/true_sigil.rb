# frozen_string_literal: true

require "rubocop"
require_relative "has_sigil"

module RuboCop
  module Cop
    module Sorbet
      # Makes the Sorbet `true` sigil mandatory in all files.
      class TrueSigil < HasSigil
        def minimum_strictness
          "true"
        end
      end
    end
  end
end

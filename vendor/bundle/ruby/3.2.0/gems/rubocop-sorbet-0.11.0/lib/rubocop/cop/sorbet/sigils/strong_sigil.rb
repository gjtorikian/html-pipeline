# frozen_string_literal: true

require "rubocop"
require_relative "has_sigil"

module RuboCop
  module Cop
    module Sorbet
      # Makes the Sorbet `strong` sigil mandatory in all files.
      class StrongSigil < HasSigil
        def minimum_strictness
          "strong"
        end
      end
    end
  end
end

# frozen_string_literal: true

require "rubocop"
require_relative "has_sigil"

module RuboCop
  module Cop
    module Sorbet
      # Makes the Sorbet `strict` sigil mandatory in all files.
      #
      # @safety
      #   This cop is unsafe because Sorbet sigils may not exist yet when it is run.
      #
      # @example
      #
      #   # bad
      #   # typed: true
      #
      #   # bad
      #   # typed: false
      #
      #   # good
      #   # typed: strict
      #
      class StrictSigil < HasSigil
        def minimum_strictness
          "strict"
        end
      end
    end
  end
end

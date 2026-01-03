# typed: strict
# frozen_string_literal: true

module YARDSorbet
  # Extract & re-add directives to a docstring
  module Directives
    extend T::Sig

    sig { params(docstring: T.nilable(String)).returns([YARD::Docstring, T::Array[String]]) }
    def self.extract_directives(docstring)
      parser = YARD::DocstringParser.new.parse(docstring)
      # Directives are already parsed at this point, and there doesn't
      # seem to be an API to tweeze them from one node to another without
      # managing YARD internal state. Instead, we just extract them from
      # the raw text and re-attach them.
      directives = parser.raw_text&.split("\n")&.select { _1.start_with?('@!') } || []
      [parser.to_docstring, directives]
    end

    sig { params(docstring: String, directives: T::Array[String]).void }
    def self.add_directives(docstring, directives) = directives.each { docstring.concat("\n#{_1}") }
  end
end

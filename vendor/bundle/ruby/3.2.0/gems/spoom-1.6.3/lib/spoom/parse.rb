# typed: strict
# frozen_string_literal: true

require "spoom/visitor"

module Spoom
  class ParseError < Error; end

  class << self
    #: (String ruby, file: String) -> Prism::Node
    def parse_ruby(ruby, file:)
      result = Prism.parse(ruby)
      unless result.success?
        message = +"Error while parsing #{file}:\n"

        result.errors.each do |e|
          message << "- #{e.message} (at #{e.location.start_line}:#{e.location.start_column})\n"
        end

        raise ParseError, message
      end

      result.value
    end

    #: (String ruby, file: String) -> [Prism::Node, Array[Prism::Comment]]
    def parse_ruby_with_comments(ruby, file:)
      result = Prism.parse(ruby)
      unless result.success?
        message = +"Error while parsing #{file}:\n"

        result.errors.each do |e|
          message << "- #{e.message} (at #{e.location.start_line}:#{e.location.start_column})\n"
        end

        raise ParseError, message
      end

      [result.value, result.comments]
    end
  end
end

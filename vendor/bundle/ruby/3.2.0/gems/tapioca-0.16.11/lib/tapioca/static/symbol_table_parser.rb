# typed: strict
# frozen_string_literal: true

module Tapioca
  module Static
    class SymbolTableParser
      extend T::Sig

      SKIP_PARSE_KINDS = T.let(["CLASS_OR_MODULE", "STATIC_FIELD"].freeze, T::Array[String])

      class << self
        extend T::Sig

        sig { params(json_string: String).returns(T::Set[String]) }
        def parse_json(json_string)
          obj = JSON.parse(json_string)

          parser = SymbolTableParser.new
          parser.parse_object(obj)
          parser.symbols
        rescue JSON::ParserError
          Set.new
        end
      end

      sig { returns(T::Set[String]) }
      attr_reader :symbols

      sig { void }
      def initialize
        @symbols = T.let(Set.new, T::Set[String])
        @parents = T.let([], T::Array[String])
      end

      sig { params(object: T::Hash[String, T.untyped]).void }
      def parse_object(object)
        children = object.fetch("children", [])

        children.each do |child|
          kind = child.fetch("kind")
          name = child.fetch("name")
          name = name.fetch("name") if name.is_a?(Hash)

          next if name.nil?
          next unless SKIP_PARSE_KINDS.include?(kind)

          # Turn singleton class names to attached class names
          if (match_data = name.match(/<Class:(.*)>/))
            name = match_data[1]
          end

          next if name.match?(/[<>()$]/)
          next if name.match?(/^[0-9]+$/)
          next if name == "T::Helpers"

          @symbols.add(fully_qualified_name(name))

          @parents << name
          parse_object(child)
          @parents.pop
        end
      end

      sig { params(name: String).returns(String) }
      def fully_qualified_name(name)
        [*@parents, name].join("::")
      end
    end
  end
end

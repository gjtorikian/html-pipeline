# typed: strict
# frozen_string_literal: true

require_relative "../../printer"
require "set"

module Spoom
  module LSP
    module PrintableSymbol
      extend T::Sig
      extend T::Helpers

      interface!

      sig { abstract.params(printer: SymbolPrinter).void }
      def accept_printer(printer); end
    end

    class Hover < T::Struct
      include PrintableSymbol

      const :contents, String
      const :range, T.nilable(Range)

      class << self
        #: (Hash[untyped, untyped] json) -> Hover
        def from_json(json)
          Hover.new(
            contents: json["contents"]["value"],
            range: json["range"] ? Range.from_json(json["range"]) : nil,
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print("#{contents}\n")
        printer.print_object(range) if range
      end

      #: -> String
      def to_s
        "#{contents} (#{range})."
      end
    end

    class Position < T::Struct
      include PrintableSymbol

      const :line, Integer
      const :char, Integer

      class << self
        #: (Hash[untyped, untyped] json) -> Position
        def from_json(json)
          Position.new(
            line: json["line"].to_i,
            char: json["character"].to_i,
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print_colored("#{line}:#{char}", Color::LIGHT_BLACK)
      end

      #: -> String
      def to_s
        "#{line}:#{char}"
      end
    end

    class Range < T::Struct
      include PrintableSymbol

      const :start, Position
      const :end, Position

      class << self
        #: (Hash[untyped, untyped] json) -> Range
        def from_json(json)
          Range.new(
            start: Position.from_json(json["start"]),
            end: Position.from_json(json["end"]),
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print_object(start)
        printer.print_colored("-", Color::LIGHT_BLACK)
        printer.print_object(self.end)
      end

      #: -> String
      def to_s
        "#{start}-#{self.end}"
      end
    end

    class Location < T::Struct
      include PrintableSymbol

      const :uri, String
      const :range, LSP::Range

      class << self
        #: (Hash[untyped, untyped] json) -> Location
        def from_json(json)
          Location.new(
            uri: json["uri"],
            range: Range.from_json(json["range"]),
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print_colored("#{printer.clean_uri(uri)}:", Color::LIGHT_BLACK)
        printer.print_object(range)
      end

      #: -> String
      def to_s
        "#{uri}:#{range}"
      end
    end

    class SignatureHelp < T::Struct
      include PrintableSymbol

      const :label, T.nilable(String)
      const :doc, Object # TODO
      const :params, T::Array[T.untyped] # TODO

      class << self
        #: (Hash[untyped, untyped] json) -> SignatureHelp
        def from_json(json)
          SignatureHelp.new(
            label: json["label"],
            doc: json["documentation"],
            params: json["parameters"],
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print(label)
        printer.print("(")
        printer.print(params.map { |l| "#{l["label"]}: #{l["documentation"]}" }.join(", "))
        printer.print(")")
      end

      #: -> String
      def to_s
        "#{label}(#{params})."
      end
    end

    class Diagnostic < T::Struct
      include PrintableSymbol

      const :range, LSP::Range
      const :code, Integer
      const :message, String
      const :information, Object

      class << self
        #: (Hash[untyped, untyped] json) -> Diagnostic
        def from_json(json)
          Diagnostic.new(
            range: Range.from_json(json["range"]),
            code: json["code"].to_i,
            message: json["message"],
            information: json["relatedInformation"],
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print(to_s)
      end

      #: -> String
      def to_s
        "Error: #{message} (#{code})."
      end
    end

    class DocumentSymbol < T::Struct
      include PrintableSymbol

      const :name, String
      const :detail, T.nilable(String)
      const :kind, Integer
      const :location, T.nilable(Location)
      const :range, T.nilable(Range)
      const :children, T::Array[DocumentSymbol]

      class << self
        #: (Hash[untyped, untyped] json) -> DocumentSymbol
        def from_json(json)
          DocumentSymbol.new(
            name: json["name"],
            detail: json["detail"],
            kind: json["kind"],
            location: json["location"] ? Location.from_json(json["location"]) : nil,
            range: json["range"] ? Range.from_json(json["range"]) : nil,
            children: json["children"] ? json["children"].map { |symbol| DocumentSymbol.from_json(symbol) } : [],
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        h = serialize.hash
        return if printer.seen.include?(h)

        printer.seen.add(h)

        printer.printt
        printer.print(kind_string)
        printer.print(" ")
        printer.print_colored(name, Color::BLUE, Color::BOLD)
        printer.print_colored(" (", Color::LIGHT_BLACK)
        if range
          printer.print_object(range)
        elsif location
          printer.print_object(location)
        end
        printer.print_colored(")", Color::LIGHT_BLACK)
        printer.printn
        unless children.empty?
          printer.indent
          printer.print_objects(children)
          printer.dedent
        end
        # TODO: also display details?
      end

      #: -> String
      def to_s
        "#{name} (#{range})"
      end

      #: -> String
      def kind_string
        SYMBOL_KINDS[kind] || "<unknown:#{kind}>"
      end

      SYMBOL_KINDS = {
        1 => "file",
        2 => "module",
        3 => "namespace",
        4 => "package",
        5 => "class",
        6 => "def",
        7 => "property",
        8 => "field",
        9 => "constructor",
        10 => "enum",
        11 => "interface",
        12 => "function",
        13 => "variable",
        14 => "const",
        15 => "string",
        16 => "number",
        17 => "boolean",
        18 => "array",
        19 => "object",
        20 => "key",
        21 => "null",
        22 => "enum_member",
        23 => "struct",
        24 => "event",
        25 => "operator",
        26 => "type_parameter",
      } #: Hash[Integer, String]
    end

    class SymbolPrinter < Printer
      #: Set[Integer]
      attr_reader :seen

      #: String?
      attr_accessor :prefix

      #: (?out: (IO | StringIO), ?colors: bool, ?indent_level: Integer, ?prefix: String?) -> void
      def initialize(out: $stdout, colors: true, indent_level: 0, prefix: nil)
        super(out: out, colors: colors, indent_level: indent_level)
        @seen = Set.new #: Set[Integer]
        @out = out
        @colors = colors
        @indent_level = indent_level
        @prefix = prefix
      end

      #: (PrintableSymbol? object) -> void
      def print_object(object)
        return unless object

        object.accept_printer(self)
      end

      #: (Array[PrintableSymbol] objects) -> void
      def print_objects(objects)
        objects.each { |object| print_object(object) }
      end

      #: (String uri) -> String
      def clean_uri(uri)
        prefix = self.prefix
        return uri unless prefix

        uri.delete_prefix(prefix)
      end

      #: (Array[PrintableSymbol] objects) -> void
      def print_list(objects)
        objects.each do |object|
          printt
          print("* ")
          print_object(object)
          printn
        end
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class Error < Spoom::Error; end

    class Comment
      #: String
      attr_reader :string

      #: Location
      attr_reader :location

      #: (String string, Location location) -> void
      def initialize(string, location)
        @string = string
        @location = location
      end
    end

    # A Symbol is a uniquely named entity in the Ruby codebase
    #
    # A symbol can have multiple definitions, e.g. a class can be reopened.
    # Sometimes a symbol can have multiple definitions of different types,
    # e.g. `foo` method can be defined both as a method and as an attribute accessor.
    class Symbol
      # The full, unique name of this symbol
      #: String
      attr_reader :full_name

      # The definitions of this symbol (where it exists in the code)
      #: Array[SymbolDef]
      attr_reader :definitions

      #: (String full_name) -> void
      def initialize(full_name)
        @full_name = full_name
        @definitions = [] #: Array[SymbolDef]
      end

      # The short name of this symbol
      #: -> String
      def name
        T.must(@full_name.split("::").last)
      end

      #: -> String
      def to_s
        @full_name
      end
    end

    class UnresolvedSymbol < Symbol
      # @override
      #: -> String
      def to_s
        "<#{@full_name}>"
      end
    end

    # A SymbolDef is a definition of a Symbol
    #
    # It can be a class, module, constant, method, etc.
    # A SymbolDef has a location pointing to the actual code that defines the symbol.
    class SymbolDef
      extend T::Helpers

      abstract!

      # The symbol this definition belongs to
      #: Symbol
      attr_reader :symbol

      # The enclosing namespace this definition belongs to
      #: Namespace?
      attr_reader :owner

      # The actual code location of this definition
      #: Location
      attr_reader :location

      # The comments associated with this definition
      #: Array[Comment]
      attr_reader :comments

      #: (Symbol symbol, owner: Namespace?, location: Location, ?comments: Array[Comment]) -> void
      def initialize(symbol, owner:, location:, comments:)
        @symbol = symbol
        @owner = owner
        @location = location
        @comments = comments

        symbol.definitions << self
        owner.children << self if owner
      end

      # The full name of the symbol this definition belongs to
      #: -> String
      def full_name
        @symbol.full_name
      end

      # The short name of the symbol this definition belongs to
      #: -> String
      def name
        @symbol.name
      end
    end

    # A class or module
    class Namespace < SymbolDef
      abstract!

      #: Array[SymbolDef]
      attr_reader :children

      #: Array[Mixin]
      attr_reader :mixins

      #: (Symbol symbol, owner: Namespace?, location: Location, ?comments: Array[Comment]) -> void
      def initialize(symbol, owner:, location:, comments: [])
        super(symbol, owner: owner, location: location, comments: comments)

        @children = [] #: Array[SymbolDef]
        @mixins = [] #: Array[Mixin]
      end
    end

    class SingletonClass < Namespace; end

    class Class < Namespace
      #: String?
      attr_accessor :superclass_name

      #: (Symbol symbol, owner: Namespace?, location: Location, ?superclass_name: String?, ?comments: Array[Comment]) -> void
      def initialize(symbol, owner:, location:, superclass_name: nil, comments: [])
        super(symbol, owner: owner, location: location, comments: comments)

        @superclass_name = superclass_name
      end
    end

    class Module < Namespace; end

    class Constant < SymbolDef
      #: String
      attr_reader :value

      #: (Symbol symbol, owner: Namespace?, location: Location, value: String, ?comments: Array[Comment]) -> void
      def initialize(symbol, owner:, location:, value:, comments: [])
        super(symbol, owner: owner, location: location, comments: comments)

        @value = value
      end
    end

    # A method or an attribute accessor
    class Property < SymbolDef
      abstract!

      #: Visibility
      attr_reader :visibility

      #: Array[Sig]
      attr_reader :sigs

      #: (Symbol symbol, owner: Namespace?, location: Location, visibility: Visibility, ?sigs: Array[Sig], ?comments: Array[Comment]) -> void
      def initialize(symbol, owner:, location:, visibility:, sigs: [], comments: [])
        super(symbol, owner: owner, location: location, comments: comments)

        @visibility = visibility
        @sigs = sigs
      end
    end

    class Method < Property; end

    class Attr < Property
      abstract!
    end

    class AttrReader < Attr; end
    class AttrWriter < Attr; end
    class AttrAccessor < Attr; end

    class Visibility < T::Enum
      enums do
        Public = new("public")
        Protected = new("protected")
        Private = new("private")
      end
    end

    # A mixin (include, prepend, extend) to a namespace
    class Mixin
      extend T::Helpers

      abstract!

      #: String
      attr_reader :name

      #: (String name) -> void
      def initialize(name)
        @name = name
      end
    end

    class Include < Mixin; end
    class Prepend < Mixin; end
    class Extend < Mixin; end

    # A Sorbet signature (sig block)
    class Sig
      #: String
      attr_reader :string

      #: (String string) -> void
      def initialize(string)
        @string = string
      end
    end

    # Model

    # All the symbols registered in this model
    #: Hash[String, Symbol]
    attr_reader :symbols

    #: Poset[Symbol]
    attr_reader :symbols_hierarchy

    #: -> void
    def initialize
      @symbols = {} #: Hash[String, Symbol]
      @symbols_hierarchy = Poset[Symbol].new #: Poset[Symbol]
    end

    # Get a symbol by it's full name
    #
    # Raises an error if the symbol is not found
    #: (String full_name) -> Symbol
    def [](full_name)
      symbol = @symbols[full_name]
      raise Error, "Symbol not found: #{full_name}" unless symbol

      symbol
    end

    # Register a new symbol by it's full name
    #
    # If the symbol already exists, it will be returned.
    #: (String full_name) -> Symbol
    def register_symbol(full_name)
      @symbols[full_name] ||= Symbol.new(full_name)
    end

    #: (String full_name, context: Symbol) -> Symbol
    def resolve_symbol(full_name, context:)
      if full_name.start_with?("::")
        full_name = full_name.delete_prefix("::")
        return @symbols[full_name] ||= UnresolvedSymbol.new(full_name)
      end

      target = @symbols[full_name] #: Symbol?
      return target if target

      parts = context.full_name.split("::")
      until parts.empty?
        target = @symbols["#{parts.join("::")}::#{full_name}"]
        return target if target

        parts.pop
      end

      @symbols[full_name] = UnresolvedSymbol.new(full_name)
    end

    #: (Symbol symbol) -> Array[Symbol]
    def supertypes(symbol)
      poe = @symbols_hierarchy[symbol]
      poe.ancestors
    end

    #: (Symbol symbol) -> Array[Symbol]
    def subtypes(symbol)
      poe = @symbols_hierarchy[symbol]
      poe.descendants
    end

    #: -> void
    def finalize!
      compute_symbols_hierarchy!
    end

    private

    #: -> void
    def compute_symbols_hierarchy!
      @symbols.dup.each do |_full_name, symbol|
        symbol.definitions.each do |definition|
          next unless definition.is_a?(Namespace)

          @symbols_hierarchy.add_element(symbol)

          if definition.is_a?(Class)
            superclass_name = definition.superclass_name
            if superclass_name
              superclass = resolve_symbol(superclass_name, context: symbol)
              @symbols_hierarchy.add_direct_edge(symbol, superclass)
            end
          end

          definition.mixins.each do |mixin|
            next if mixin.is_a?(Extend)

            target = resolve_symbol(mixin.name, context: symbol)
            @symbols_hierarchy.add_direct_edge(symbol, target)
          end
        end
      end
    end
  end
end

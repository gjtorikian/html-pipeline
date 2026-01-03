# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    class Event
      extend T::Sig
      extend T::Helpers

      abstract!
    end

    class SymbolFound < Event
      extend T::Sig

      sig { returns(String) }
      attr_reader :symbol

      sig { params(symbol: String).void }
      def initialize(symbol)
        super()
        @symbol = symbol
      end
    end

    class ConstantFound < Event
      extend T::Sig

      sig { returns(String) }
      attr_reader :symbol

      sig { returns(BasicObject).checked(:never) }
      attr_reader :constant

      sig { params(symbol: String, constant: BasicObject).void.checked(:never) }
      def initialize(symbol, constant)
        super()
        @symbol = symbol
        @constant = constant
      end
    end

    class ForeignConstantFound < ConstantFound
      extend T::Sig

      sig { override.returns(Module) }
      def constant
        T.cast(@constant, Module)
      end

      sig { params(symbol: String, constant: Module).void }
      def initialize(symbol, constant)
        super
      end
    end

    class NodeAdded < Event
      extend T::Helpers
      extend T::Sig

      abstract!

      sig { returns(String) }
      attr_reader :symbol

      sig { returns(Module).checked(:never) }
      attr_reader :constant

      sig { params(symbol: String, constant: Module).void.checked(:never) }
      def initialize(symbol, constant)
        super()
        @symbol = symbol
        @constant = constant
      end
    end

    class ConstNodeAdded < NodeAdded
      extend T::Sig

      sig { returns(RBI::Const) }
      attr_reader :node

      sig { params(symbol: String, constant: Module, node: RBI::Const).void.checked(:never) }
      def initialize(symbol, constant, node)
        super(symbol, constant)
        @node = node
      end
    end

    class ScopeNodeAdded < NodeAdded
      extend T::Sig

      sig { returns(RBI::Scope) }
      attr_reader :node

      sig { params(symbol: String, constant: Module, node: RBI::Scope).void.checked(:never) }
      def initialize(symbol, constant, node)
        super(symbol, constant)
        @node = node
      end
    end

    class ForeignScopeNodeAdded < ScopeNodeAdded; end

    class MethodNodeAdded < NodeAdded
      extend T::Sig

      sig { returns(UnboundMethod) }
      attr_reader :method

      sig { returns(RBI::Method) }
      attr_reader :node

      sig { returns(T.untyped) }
      attr_reader :signature

      sig { returns(T::Array[[Symbol, String]]) }
      attr_reader :parameters

      sig do
        params(
          symbol: String,
          constant: Module,
          method: UnboundMethod,
          node: RBI::Method,
          signature: T.untyped,
          parameters: T::Array[[Symbol, String]],
        ).void.checked(:never)
      end
      def initialize(symbol, constant, method, node, signature, parameters) # rubocop:disable Metrics/ParameterLists
        super(symbol, constant)
        @node = node
        @method = method
        @signature = signature
        @parameters = parameters
      end
    end
  end
end

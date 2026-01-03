# typed: strict
# frozen_string_literal: true

module RBI
  # The base class for all RBI types.
  # @abstract
  class Type
    # Simple

    # A type that represents a simple class name like `String` or `Foo`.
    #
    # It can also be a qualified name like `::Foo` or `Foo::Bar`.
    class Simple < Type
      #: String
      attr_reader :name

      #: (String name) -> void
      def initialize(name)
        super()
        @name = name
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Simple === other && @name == other.name
      end

      # @override
      #: -> String
      def to_rbi
        @name
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # Literals

    # `T.anything`.
    class Anything < Type
      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Anything === other
      end

      # @override
      #: -> String
      def to_rbi
        "::T.anything"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # `T.attached_class`.
    class AttachedClass < Type
      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        AttachedClass === other
      end

      # @override
      #: -> String
      def to_rbi
        "::T.attached_class"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # `T::Boolean`.
    class Boolean < Type
      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Boolean === other
      end

      # @override
      #: -> String
      def to_rbi
        "T::Boolean"
      end

      # @override
      #: -> Type
      def normalize
        Type::Any.new([Type.simple("TrueClass"), Type.simple("FalseClass")])
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # `T.noreturn`.
    class NoReturn < Type
      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        NoReturn === other
      end

      # @override
      #: -> String
      def to_rbi
        "::T.noreturn"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # `T.self_type`.
    class SelfType < Type
      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        SelfType === other
      end

      # @override
      #: -> String
      def to_rbi
        "::T.self_type"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # `T.untyped`.
    class Untyped < Type
      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Untyped === other
      end

      # @override
      #: -> String
      def to_rbi
        "::T.untyped"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # `void`.
    class Void < Type
      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Void === other
      end

      # @override
      #: -> String
      def to_rbi
        "void"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # Composites

    # The class of another type like `T::Class[Foo]`.
    class Class < Type
      #: Type
      attr_reader :type

      #: (Type type) -> void
      def initialize(type)
        super()
        @type = type
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Class === other && @type == other.type
      end

      # @override
      #: -> String
      def to_rbi
        "T::Class[#{@type}]"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # The module of another type like `T::Module[Foo]`.
    class Module < Type
      #: Type
      attr_reader :type

      #: (Type type) -> void
      def initialize(type)
        super()
        @type = type
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Module === other && @type == other.type
      end

      # @override
      #: -> String
      def to_rbi
        "T::Module[#{@type}]"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # The singleton class of another type like `T.class_of(Foo)`.
    class ClassOf < Type
      #: Simple
      attr_reader :type

      #: Type?
      attr_reader :type_parameter

      #: (Simple type, ?Type? type_parameter) -> void
      def initialize(type, type_parameter = nil)
        super()
        @type = type
        @type_parameter = type_parameter
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        ClassOf === other && @type == other.type && @type_parameter == other.type_parameter
      end

      # @override
      #: -> String
      def to_rbi
        if @type_parameter
          "::T.class_of(#{@type.to_rbi})[#{@type_parameter.to_rbi}]"
        else
          "::T.class_of(#{@type.to_rbi})"
        end
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # A type that can be `nil` like `T.nilable(String)`.
    class Nilable < Type
      #: Type
      attr_reader :type

      #: (Type type) -> void
      def initialize(type)
        super()
        @type = type
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Nilable === other && @type == other.type
      end

      # @override
      #: -> String
      def to_rbi
        "::T.nilable(#{@type.to_rbi})"
      end

      # @override
      #: -> Type
      def normalize
        Type::Any.new([Type.simple("NilClass"), @type.normalize])
      end

      # @override
      #: -> Type
      def simplify
        case @type
        when Nilable
          @type.simplify
        when Untyped
          @type.simplify
        else
          self
        end
      end
    end

    # A type that is composed of multiple types like `T.all(String, Integer)`.
    # @abstract
    class Composite < Type
      #: Array[Type]
      attr_reader :types

      #: (Array[Type] types) -> void
      def initialize(types)
        super()
        @types = types
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        self.class === other && @types.sort_by(&:to_rbi) == other.types.sort_by(&:to_rbi)
      end
    end

    # A type that is intersection of multiple types like `T.all(String, Integer)`.
    class All < Composite
      # @override
      #: -> String
      def to_rbi
        "::T.all(#{@types.map(&:to_rbi).join(", ")})"
      end

      # @override
      #: -> Type
      def normalize
        flattened = @types.flat_map do |type|
          type = type.normalize
          case type
          when All
            type.types.map(&:normalize)
          else
            type
          end
        end.uniq

        if flattened.size == 1
          return flattened.first #: as !nil
        end

        All.new(flattened)
      end

      # @override
      #: -> Type
      def simplify
        type = normalize

        case type
        when All
          All.new(type.types.map(&:simplify))
        else
          type.simplify
        end
      end
    end

    # A type that is union of multiple types like `T.any(String, Integer)`.
    class Any < Composite
      # @override
      #: -> String
      def to_rbi
        "::T.any(#{@types.map(&:to_rbi).join(", ")})"
      end

      #: -> bool
      def nilable?
        @types.any? { |type| type.nilable? || (type.is_a?(Simple) && type.name == "NilClass") }
      end

      # @override
      #: -> Type
      def normalize
        flattened = @types.flat_map do |type|
          type = type.normalize
          case type
          when Any
            type.types.map(&:normalize)
          else
            type
          end
        end.uniq

        if flattened.size == 1
          flattened.first #: as !nil
        else
          Any.new(flattened)
        end
      end

      # @override
      #: -> Type
      def simplify
        type = normalize
        return type.simplify unless type.is_a?(Any)

        types = type.types.map(&:simplify)
        return Untyped.new if types.any? { |type| type.is_a?(Untyped) }

        has_true_class = types.any? { |type| type.is_a?(Simple) && type.name == "TrueClass" }
        has_false_class = types.any? { |type| type.is_a?(Simple) && type.name == "FalseClass" }

        if has_true_class && has_false_class
          types = types.reject { |type| type.is_a?(Simple) && (type.name == "TrueClass" || type.name == "FalseClass") }
          types << Type.boolean
        end

        is_nilable = false #: bool

        types = types.filter_map do |type|
          case type
          when Simple
            if type.name == "NilClass"
              is_nilable = true
              nil
            else
              type
            end
          when Nilable
            is_nilable = true
            type.type
          else
            type
          end
        end.uniq

        final_type = if types.size == 1
          types.first #: as !nil
        else
          Any.new(types)
        end

        if is_nilable
          return Nilable.new(final_type)
        end

        final_type
      end
    end

    # Generics

    # A generic type like `T::Array[String]` or `T::Hash[Symbol, Integer]`.
    class Generic < Type
      #: String
      attr_reader :name

      #: Array[Type]
      attr_reader :params

      #: (String name, *Type params) -> void
      def initialize(name, *params)
        super()
        @name = name
        @params = params #: Array[Type]
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Generic === other && @name == other.name && @params == other.params
      end

      # @override
      #: -> String
      def to_rbi
        "#{@name}[#{@params.map(&:to_rbi).join(", ")}]"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # A type parameter like `T.type_parameter(:U)`.
    class TypeParameter < Type
      #: Symbol
      attr_reader :name

      #: (Symbol name) -> void
      def initialize(name)
        super()
        @name = name
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        TypeParameter === other && @name == other.name
      end

      # @override
      #: -> String
      def to_rbi
        "::T.type_parameter(#{@name.inspect})"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # A type alias that references another type by name like `MyTypeAlias`.
    class TypeAlias < Type
      #: String
      attr_reader :name

      #: Type
      attr_reader :aliased_type

      #: (String name, Type aliased_type) -> void
      def initialize(name, aliased_type)
        super()
        @name = name
        @aliased_type = aliased_type
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        TypeAlias === other && @name == other.name && @aliased_type == other.aliased_type
      end

      # @override
      #: -> String
      def to_rbi
        "#{name} = ::T.type_alias { #{aliased_type.to_rbi} }"
      end

      # @override
      #: -> Type
      def normalize
        TypeAlias.new(name, aliased_type.normalize)
      end

      # @override
      #: -> Type
      def simplify
        TypeAlias.new(name, aliased_type.simplify)
      end
    end

    # Tuples and shapes

    # A tuple type like `[String, Integer]`.
    class Tuple < Type
      #: Array[Type]
      attr_reader :types

      #: (Array[Type] types) -> void
      def initialize(types)
        super()
        @types = types
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Tuple === other && @types == other.types
      end

      # @override
      #: -> String
      def to_rbi
        "[#{@types.map(&:to_rbi).join(", ")}]"
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # A shape type like `{name: String, age: Integer}`.
    class Shape < Type
      #: Hash[(String | Symbol), Type]
      attr_reader :types

      #: (Hash[(String | Symbol), Type] types) -> void
      def initialize(types)
        super()
        @types = types
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        Shape === other && @types.sort_by { |t| t.first.to_s } == other.types.sort_by { |t| t.first.to_s }
      end

      # @override
      #: -> String
      def to_rbi
        if @types.empty?
          "{}"
        else
          "{ " + @types.map { |name, type| "#{name}: #{type.to_rbi}" }.join(", ") + " }"
        end
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # Proc

    # A proc type like `T.proc.void`.
    class Proc < Type
      #: Hash[Symbol, Type]
      attr_reader :proc_params

      #: Type
      attr_reader :proc_returns

      #: Type?
      attr_reader :proc_bind

      #: -> void
      def initialize
        super
        @proc_params = {} #: Hash[Symbol, Type]
        @proc_returns = Type.void #: Type
        @proc_bind = nil #: Type?
      end

      # @override
      #: (BasicObject other) -> bool
      def ==(other)
        return false unless Proc === other
        return false unless @proc_params == other.proc_params
        return false unless @proc_returns == other.proc_returns
        return false unless @proc_bind == other.proc_bind

        true
      end

      #: (**Type params) -> self
      def params(**params)
        @proc_params = params
        self
      end

      #: (untyped type) -> self
      def returns(type)
        @proc_returns = type
        self
      end

      #: -> self
      def void
        @proc_returns = RBI::Type.void
        self
      end

      #: (untyped type) -> self
      def bind(type)
        @proc_bind = type
        self
      end

      # @override
      #: -> String
      def to_rbi
        rbi = +"::T.proc"

        if @proc_bind
          rbi << ".bind(#{@proc_bind})"
        end

        unless @proc_params.empty?
          rbi << ".params("
          rbi << @proc_params.map { |name, type| "#{name}: #{type.to_rbi}" }.join(", ")
          rbi << ")"
        end

        rbi << case @proc_returns
        when Void
          ".void"
        else
          ".returns(#{@proc_returns})"
        end

        rbi
      end

      # @override
      #: -> Type
      def normalize
        self
      end

      # @override
      #: -> Type
      def simplify
        self
      end
    end

    # Type builder

    class << self
      # Simple

      # Builds a simple type like `String` or `::Foo::Bar`.
      #
      # It raises a `NameError` if the name is not a valid Ruby class identifier.
      #: (String name) -> Simple
      def simple(name)
        # TODO: should we allow creating the instance anyway and move this to a `validate!` method?
        raise NameError, "Invalid type name: `#{name}`" unless valid_identifier?(name)

        Simple.new(name)
      end

      # Literals

      # Builds a type that represents `T.anything`.
      #: -> Anything
      def anything
        Anything.new
      end

      # Builds a type that represents `T.attached_class`.
      #: -> AttachedClass
      def attached_class
        AttachedClass.new
      end

      # Builds a type that represents `T::Boolean`.
      #: -> Boolean
      def boolean
        Boolean.new
      end

      # Builds a type that represents `T.noreturn`.
      #: -> NoReturn
      def noreturn
        NoReturn.new
      end

      # Builds a type that represents `T.self_type`.
      #: -> SelfType
      def self_type
        SelfType.new
      end

      # Builds a type that represents `T.untyped`.
      #: -> Untyped
      def untyped
        Untyped.new
      end

      # Builds a type that represents `void`.
      #: -> Void
      def void
        Void.new
      end

      # Composites

      # Builds a type that represents the class of another type like `T::Class[Foo]`.
      #: (Type type) -> Class
      def t_class(type)
        Class.new(type)
      end

      # Builds a type that represents the module of another type like `T::Module[Foo]`.
      #: (Type type) -> Module
      def t_module(type)
        Module.new(type)
      end

      # Builds a type that represents the singleton class of another type like `T.class_of(Foo)`.
      #: (Simple type, ?Type? type_parameter) -> ClassOf
      def class_of(type, type_parameter = nil)
        ClassOf.new(type, type_parameter)
      end

      # Builds a type that represents a nilable of another type like `T.nilable(String)`.
      #
      # Note that this method transforms types such as `T.nilable(T.untyped)` into `T.untyped`, so
      # it may return something other than a `RBI::Type::Nilable`.
      #: (Type type) -> Type
      def nilable(type)
        nilable = Nilable.new(type)
        nilable.simplify
      end

      # Builds a type that represents an intersection of multiple types like `T.all(String, Integer)`.
      #
      # Note that this method transforms types such as `T.all(String, String)` into `String`, so
      # it may return something other than a `All`.
      #: (Type type1, Type type2, *Type types) -> Type
      def all(type1, type2, *types)
        All.new([type1, type2, *types]).simplify
      end

      # Builds a type that represents a union of multiple types like `T.any(String, Integer)`.
      #
      # Note that this method transforms types such as `T.any(String, NilClass)` into `T.nilable(String)`, so
      # it may return something other than a `Any`.
      #: (Type type1, Type type2, *Type types) -> Type
      def any(type1, type2, *types)
        Any.new([type1, type2, *types]).simplify
      end

      # Generics

      # Builds a type that represents a generic type like `T::Array[String]` or `T::Hash[Symbol, Integer]`.
      #: (String name, *(Type | Array[Type]) params) -> Generic
      def generic(name, *params)
        Generic.new(name, *params.flatten)
      end

      # Builds a type that represents a type parameter like `T.type_parameter(:U)`.
      #: (Symbol name) -> TypeParameter
      def type_parameter(name)
        TypeParameter.new(name)
      end

      # Builds a type that represents a type alias like `MyTypeAlias`.
      #: (String name, Type aliased_type) -> TypeAlias
      def type_alias(name, aliased_type)
        TypeAlias.new(name, aliased_type)
      end

      # Tuples and shapes

      # Builds a type that represents a tuple type like `[String, Integer]`.
      #: (*(Type | Array[Type]) types) -> Tuple
      def tuple(*types)
        Tuple.new(types.flatten)
      end

      # Builds a type that represents a shape type like `{name: String, age: Integer}`.
      #: (?Hash[(String | Symbol), Type] types) -> Shape
      def shape(types = {})
        Shape.new(types)
      end

      # Proc

      # Builds a type that represents a proc type like `T.proc.void`.
      #: -> Proc
      def proc
        Proc.new
      end

      private

      #: (String name) -> bool
      def valid_identifier?(name)
        Prism.parse("class self::#{name.delete_prefix("::")}; end").success?
      end
    end

    #: -> void
    def initialize
      @nilable = false #: bool
    end

    # Returns a new type that is `nilable` if it is not already.
    #
    # If the type is already nilable, it returns itself.
    # ```ruby
    # type = RBI::Type.simple("String")
    # type.to_rbi # => "String"
    # type.nilable.to_rbi # => "::T.nilable(String)"
    # type.nilable.nilable.to_rbi # => "::T.nilable(String)"
    # ```
    #: -> Type
    def nilable
      Type.nilable(self)
    end

    # Returns the non-nilable version of the type.
    # If the type is already non-nilable, it returns itself.
    # If the type is nilable, it returns the inner type.
    #
    # ```ruby
    # type = RBI::Type.nilable(RBI::Type.simple("String"))
    # type.to_rbi # => "::T.nilable(String)"
    # type.non_nilable.to_rbi # => "String"
    # type.non_nilable.non_nilable.to_rbi # => "String"
    # ```
    #: -> Type
    def non_nilable
      # TODO: Should this logic be moved into a builder method?
      case self
      when Nilable
        type
      else
        self
      end
    end

    # Returns whether the type is nilable.
    #: -> bool
    def nilable?
      is_a?(Nilable)
    end

    # Returns a normalized version of the type.
    #
    # Normalized types are meant to be easier to process, not to read.
    # For example, `T.any(TrueClass, FalseClass)` instead of `T::Boolean` or
    # `T.any(String, NilClass)` instead of `T.nilable(String)`.
    #
    # This is the inverse of `#simplify`.
    #
    # @abstract
    #: -> Type
    def normalize = raise NotImplementedError, "Abstract method called"

    # Returns a simplified version of the type.
    #
    # Simplified types are meant to be easier to read, not to process.
    # For example, `T::Boolean` instead of `T.any(TrueClass, FalseClass)` or
    # `T.nilable(String)` instead of `T.any(String, NilClass)`.
    #
    # This is the inverse of `#normalize`.
    #
    # @abstract
    #: -> Type
    def simplify = raise NotImplementedError, "Abstract method called"

    # @abstract
    #: (BasicObject) -> bool
    def ==(other) = raise NotImplementedError, "Abstract method called"

    #: (BasicObject other) -> bool
    def eql?(other)
      self == other
    end

    # @override
    #: -> Integer
    def hash
      to_rbi.hash
    end

    # @abstract
    #: -> String
    def to_rbi = raise NotImplementedError, "Abstract method called"

    # @override
    #: -> String
    def to_s
      to_rbi
    end
  end
end

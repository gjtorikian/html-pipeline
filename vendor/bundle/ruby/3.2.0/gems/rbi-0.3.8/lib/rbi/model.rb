# typed: strict
# frozen_string_literal: true

module RBI
  class ReplaceNodeError < Error; end

  # @abstract
  class Node
    #: Tree?
    attr_accessor :parent_tree

    #: Loc?
    attr_accessor :loc

    #: (?loc: Loc?) -> void
    def initialize(loc: nil)
      @parent_tree = nil
      @loc = loc
    end

    #: -> void
    def detach
      tree = parent_tree
      return unless tree

      tree.nodes.delete(self)
      self.parent_tree = nil
    end

    #: (Node node) -> void
    def replace(node)
      tree = parent_tree
      raise ReplaceNodeError, "Can't replace #{self} without a parent tree" unless tree

      index = tree.nodes.index(self)
      raise ReplaceNodeError, "Can't find #{self} in #{tree} child nodes" unless index

      tree.nodes[index] = node
      node.parent_tree = tree
      self.parent_tree = nil
    end

    #: -> Scope?
    def parent_scope
      parent = parent_tree #: Tree?
      parent = parent.parent_tree until parent.is_a?(Scope) || parent.nil?
      parent
    end
  end

  class Comment < Node
    #: String
    attr_accessor :text

    #: (String text, ?loc: Loc?) -> void
    def initialize(text, loc: nil)
      super(loc: loc)
      @text = text
    end

    #: (Object other) -> bool
    def ==(other)
      return false unless other.is_a?(Comment)

      text == other.text
    end
  end

  # An arbitrary blank line that can be added both in trees and comments
  class BlankLine < Comment
    #: (?loc: Loc?) -> void
    def initialize(loc: nil)
      super("", loc: loc)
    end
  end

  # A comment representing a RBS type prefixed with `#:`
  class RBSComment < Comment
    #: (Object other) -> bool
    def ==(other)
      return false unless other.is_a?(RBSComment)

      text == other.text
    end
  end

  # @abstract
  class NodeWithComments < Node
    #: Array[Comment]
    attr_accessor :comments

    #: (?loc: Loc?, ?comments: Array[Comment]) -> void
    def initialize(loc: nil, comments: [])
      super(loc: loc)
      @comments = comments
    end

    #: -> Array[String]
    def annotations
      comments
        .select { |comment| comment.text.start_with?("@") }
        .map do |comment|
          comment.text[1..] #: as !nil
        end
    end
  end

  class Tree < NodeWithComments
    #: Array[Node]
    attr_reader :nodes

    #: (?loc: Loc?, ?comments: Array[Comment]) ?{ (Tree node) -> void } -> void
    def initialize(loc: nil, comments: [], &block)
      super(loc: loc, comments: comments)
      @nodes = [] #: Array[Node]
      block&.call(self)
    end

    #: (Node node) -> void
    def <<(node)
      node.parent_tree = self
      @nodes << node
    end

    #: -> bool
    def empty?
      nodes.empty?
    end
  end

  class File
    #: Tree
    attr_accessor :root

    #: String?
    attr_accessor :strictness

    #: Array[Comment]
    attr_accessor :comments

    #: (?strictness: String?, ?comments: Array[Comment]) ?{ (File file) -> void } -> void
    def initialize(strictness: nil, comments: [], &block)
      @root = Tree.new #: Tree
      @strictness = strictness
      @comments = comments
      block&.call(self)
    end

    #: (Node node) -> void
    def <<(node)
      @root << node
    end

    #: -> bool
    def empty?
      @root.empty?
    end
  end

  # Scopes

  # @abstract
  class Scope < Tree
    # @abstract
    #: -> String
    def fully_qualified_name = raise NotImplementedError, "Abstract method called"

    # @override
    #: -> String
    def to_s
      fully_qualified_name
    end
  end

  class Module < Scope
    #: String
    attr_accessor :name

    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) ?{ (Module node) -> void } -> void
    def initialize(name, loc: nil, comments: [], &block)
      super(loc: loc, comments: comments) {}
      @name = name
      block&.call(self)
    end

    # @override
    #: -> String
    def fully_qualified_name
      return name if name.start_with?("::")

      "#{parent_scope&.fully_qualified_name}::#{name}"
    end
  end

  class Class < Scope
    #: String
    attr_accessor :name

    #: String?
    attr_accessor :superclass_name

    #: (String name, ?superclass_name: String?, ?loc: Loc?, ?comments: Array[Comment]) ?{ (Class node) -> void } -> void
    def initialize(name, superclass_name: nil, loc: nil, comments: [], &block)
      super(loc: loc, comments: comments) {}
      @name = name
      @superclass_name = superclass_name
      block&.call(self)
    end

    # @override
    #: -> String
    def fully_qualified_name
      return name if name.start_with?("::")

      "#{parent_scope&.fully_qualified_name}::#{name}"
    end
  end

  class SingletonClass < Scope
    #: (?loc: Loc?, ?comments: Array[Comment]) ?{ (SingletonClass node) -> void } -> void
    def initialize(loc: nil, comments: [], &block)
      super {}
      block&.call(self)
    end

    # @override
    #: -> String
    def fully_qualified_name
      "#{parent_scope&.fully_qualified_name}::<self>"
    end
  end

  class Struct < Scope
    #: String
    attr_accessor :name

    #: Array[Symbol]
    attr_accessor :members

    #: bool
    attr_accessor :keyword_init

    #: (
    #|   String name,
    #|   ?members: Array[Symbol],
    #|   ?keyword_init: bool,
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment]
    #| ) ?{ (Struct struct) -> void } -> void
    def initialize(name, members: [], keyword_init: false, loc: nil, comments: [], &block)
      super(loc: loc, comments: comments) {}
      @name = name
      @members = members
      @keyword_init = keyword_init
      block&.call(self)
    end

    # @override
    #: -> String
    def fully_qualified_name
      return name if name.start_with?("::")

      "#{parent_scope&.fully_qualified_name}::#{name}"
    end
  end

  # Consts

  class Const < NodeWithComments
    #: String
    attr_reader :name, :value

    #: (String name, String value, ?loc: Loc?, ?comments: Array[Comment]) ?{ (Const node) -> void } -> void
    def initialize(name, value, loc: nil, comments: [], &block)
      super(loc: loc, comments: comments)
      @name = name
      @value = value
      block&.call(self)
    end

    #: -> String
    def fully_qualified_name
      return name if name.start_with?("::")

      "#{parent_scope&.fully_qualified_name}::#{name}"
    end

    # @override
    #: -> String
    def to_s
      fully_qualified_name
    end
  end

  # Attributes

  # @abstract
  class Attr < NodeWithComments
    #: Array[Symbol]
    attr_reader :names

    #: Visibility
    attr_accessor :visibility

    #: Array[Sig]
    attr_reader :sigs

    #: (
    #|   Symbol name,
    #|   Array[Symbol] names,
    #|   ?visibility: Visibility,
    #|   ?sigs: Array[Sig],
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment]
    #| ) -> void
    def initialize(name, names, visibility: Public.new, sigs: [], loc: nil, comments: [])
      super(loc: loc, comments: comments)
      @names = [name, *names] #: Array[Symbol]
      @visibility = visibility
      @sigs = sigs
    end

    # @abstract
    #: -> Array[String]
    def fully_qualified_names = raise NotImplementedError, "Abstract method called"
  end

  class AttrAccessor < Attr
    #: (
    #|   Symbol name,
    #|   *Symbol names,
    #|   ?visibility: Visibility,
    #|   ?sigs: Array[Sig],
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment]
    #| ) ?{ (AttrAccessor node) -> void } -> void
    def initialize(name, *names, visibility: Public.new, sigs: [], loc: nil, comments: [], &block)
      super(name, names, loc: loc, visibility: visibility, sigs: sigs, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> Array[String]
    def fully_qualified_names
      parent_name = parent_scope&.fully_qualified_name
      names.flat_map { |name| ["#{parent_name}##{name}", "#{parent_name}##{name}="] }
    end

    # @override
    #: -> String
    def to_s
      symbols = names.map { |name| ":#{name}" }.join(", ")
      "#{parent_scope&.fully_qualified_name}.attr_accessor(#{symbols})"
    end
  end

  class AttrReader < Attr
    #: (
    #|   Symbol name,
    #|   *Symbol names,
    #|   ?visibility: Visibility,
    #|   ?sigs: Array[Sig],
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment]
    #| ) ?{ (AttrReader node) -> void } -> void
    def initialize(name, *names, visibility: Public.new, sigs: [], loc: nil, comments: [], &block)
      super(name, names, loc: loc, visibility: visibility, sigs: sigs, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> Array[String]
    def fully_qualified_names
      parent_name = parent_scope&.fully_qualified_name
      names.map { |name| "#{parent_name}##{name}" }
    end

    # @override
    #: -> String
    def to_s
      symbols = names.map { |name| ":#{name}" }.join(", ")
      "#{parent_scope&.fully_qualified_name}.attr_reader(#{symbols})"
    end
  end

  class AttrWriter < Attr
    #: (
    #|   Symbol name,
    #|   *Symbol names,
    #|   ?visibility: Visibility,
    #|   ?sigs: Array[Sig],
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment]
    #| ) ?{ (AttrWriter node) -> void } -> void
    def initialize(name, *names, visibility: Public.new, sigs: [], loc: nil, comments: [], &block)
      super(name, names, loc: loc, visibility: visibility, sigs: sigs, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> Array[String]
    def fully_qualified_names
      parent_name = parent_scope&.fully_qualified_name
      names.map { |name| "#{parent_name}##{name}=" }
    end

    # @override
    #: -> String
    def to_s
      symbols = names.map { |name| ":#{name}" }.join(", ")
      "#{parent_scope&.fully_qualified_name}.attr_writer(#{symbols})"
    end
  end

  # Methods and args

  class Method < NodeWithComments
    #: String
    attr_accessor :name

    #: Array[Param]
    attr_reader :params

    #: bool
    attr_accessor :is_singleton

    #: Visibility
    attr_accessor :visibility

    #: Array[Sig]
    attr_accessor :sigs

    #: (
    #|   String name,
    #|   ?params: Array[Param],
    #|   ?is_singleton: bool,
    #|   ?visibility: Visibility,
    #|   ?sigs: Array[Sig],
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment]
    #| ) ?{ (Method node) -> void } -> void
    def initialize(
      name,
      params: [],
      is_singleton: false,
      visibility: Public.new,
      sigs: [],
      loc: nil,
      comments: [],
      &block
    )
      super(loc: loc, comments: comments)
      @name = name
      @params = params
      @is_singleton = is_singleton
      @visibility = visibility
      @sigs = sigs
      block&.call(self)
    end

    #: (Param param) -> void
    def <<(param)
      @params << param
    end

    #: (String name) -> void
    def add_param(name)
      @params << ReqParam.new(name)
    end

    #: (String name, String default_value) -> void
    def add_opt_param(name, default_value)
      @params << OptParam.new(name, default_value)
    end

    #: (String name) -> void
    def add_rest_param(name)
      @params << RestParam.new(name)
    end

    #: (String name) -> void
    def add_kw_param(name)
      @params << KwParam.new(name)
    end

    #: (String name, String default_value) -> void
    def add_kw_opt_param(name, default_value)
      @params << KwOptParam.new(name, default_value)
    end

    #: (String name) -> void
    def add_kw_rest_param(name)
      @params << KwRestParam.new(name)
    end

    #: (String name) -> void
    def add_block_param(name)
      @params << BlockParam.new(name)
    end

    #: (
    #|   ?params: Array[SigParam],
    #|   ?return_type: (String | Type),
    #|   ?is_abstract: bool,
    #|   ?is_override: bool,
    #|   ?is_overridable: bool,
    #|   ?is_final: bool,
    #|   ?type_params: Array[String],
    #|   ?checked: Symbol?) ?{ (Sig node) -> void } -> void
    def add_sig(
      params: [],
      return_type: "void",
      is_abstract: false,
      is_override: false,
      is_overridable: false,
      is_final: false,
      type_params: [],
      checked: nil,
      &block
    )
      sig = Sig.new(
        params: params,
        return_type: return_type,
        is_abstract: is_abstract,
        is_override: is_override,
        is_overridable: is_overridable,
        is_final: is_final,
        type_params: type_params,
        checked: checked,
        &block
      )
      @sigs << sig
    end

    #: -> String
    def fully_qualified_name
      if is_singleton
        "#{parent_scope&.fully_qualified_name}::#{name}"
      else
        "#{parent_scope&.fully_qualified_name}##{name}"
      end
    end

    # @override
    #: -> String
    def to_s
      "#{fully_qualified_name}(#{params.join(", ")})"
    end
  end

  # @abstract
  class Param < NodeWithComments
    #: String
    attr_reader :name

    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) -> void
    def initialize(name, loc: nil, comments: [])
      super(loc: loc, comments: comments)
      @name = name
    end

    # @override
    #: -> String
    def to_s
      name
    end
  end

  class ReqParam < Param
    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) ?{ (ReqParam node) -> void } -> void
    def initialize(name, loc: nil, comments: [], &block)
      super(name, loc: loc, comments: comments)
      block&.call(self)
    end

    #: (Object? other) -> bool
    def ==(other)
      ReqParam === other && name == other.name
    end
  end

  class OptParam < Param
    #: String
    attr_reader :value

    #: (String name, String value, ?loc: Loc?, ?comments: Array[Comment]) ?{ (OptParam node) -> void } -> void
    def initialize(name, value, loc: nil, comments: [], &block)
      super(name, loc: loc, comments: comments)
      @value = value
      block&.call(self)
    end

    #: (Object? other) -> bool
    def ==(other)
      OptParam === other && name == other.name
    end
  end

  class RestParam < Param
    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) ?{ (RestParam node) -> void } -> void
    def initialize(name, loc: nil, comments: [], &block)
      super(name, loc: loc, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> String
    def to_s
      "*#{name}"
    end

    #: (Object? other) -> bool
    def ==(other)
      RestParam === other && name == other.name
    end
  end

  class KwParam < Param
    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) ?{ (KwParam node) -> void } -> void
    def initialize(name, loc: nil, comments: [], &block)
      super(name, loc: loc, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> String
    def to_s
      "#{name}:"
    end

    #: (Object? other) -> bool
    def ==(other)
      KwParam === other && name == other.name
    end
  end

  class KwOptParam < Param
    #: String
    attr_reader :value

    #: (String name, String value, ?loc: Loc?, ?comments: Array[Comment]) ?{ (KwOptParam node) -> void } -> void
    def initialize(name, value, loc: nil, comments: [], &block)
      super(name, loc: loc, comments: comments)
      @value = value
      block&.call(self)
    end

    # @override
    #: -> String
    def to_s
      "#{name}:"
    end

    #: (Object? other) -> bool
    def ==(other)
      KwOptParam === other && name == other.name
    end
  end

  class KwRestParam < Param
    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) ?{ (KwRestParam node) -> void } -> void
    def initialize(name, loc: nil, comments: [], &block)
      super(name, loc: loc, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> String
    def to_s
      "**#{name}:"
    end

    #: (Object? other) -> bool
    def ==(other)
      KwRestParam === other && name == other.name
    end
  end

  class BlockParam < Param
    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) ?{ (BlockParam node) -> void } -> void
    def initialize(name, loc: nil, comments: [], &block)
      super(name, loc: loc, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> String
    def to_s
      "&#{name}"
    end

    #: (Object? other) -> bool
    def ==(other)
      BlockParam === other && name == other.name
    end
  end

  # Mixins

  # @abstract
  class Mixin < NodeWithComments
    #: Array[String]
    attr_reader :names

    #: (String name, Array[String] names, ?loc: Loc?, ?comments: Array[Comment]) -> void
    def initialize(name, names, loc: nil, comments: [])
      super(loc: loc, comments: comments)
      @names = [name, *names] #: Array[String]
    end
  end

  class Include < Mixin
    #: (String name, *String names, ?loc: Loc?, ?comments: Array[Comment]) ?{ (Include node) -> void } -> void
    def initialize(name, *names, loc: nil, comments: [], &block)
      super(name, names, loc: loc, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> String
    def to_s
      "#{parent_scope&.fully_qualified_name}.include(#{names.join(", ")})"
    end
  end

  class Extend < Mixin
    #: (String name, *String names, ?loc: Loc?, ?comments: Array[Comment]) ?{ (Extend node) -> void } -> void
    def initialize(name, *names, loc: nil, comments: [], &block)
      super(name, names, loc: loc, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> String
    def to_s
      "#{parent_scope&.fully_qualified_name}.extend(#{names.join(", ")})"
    end
  end

  # Visibility

  # @abstract
  class Visibility < NodeWithComments
    #: Symbol
    attr_reader :visibility

    #: (Symbol visibility, ?loc: Loc?, ?comments: Array[Comment]) -> void
    def initialize(visibility, loc: nil, comments: [])
      super(loc: loc, comments: comments)
      @visibility = visibility
    end

    #: (Object? other) -> bool
    def ==(other)
      return false unless other.is_a?(Visibility)

      visibility == other.visibility
    end

    #: -> bool
    def public?
      visibility == :public
    end

    #: -> bool
    def protected?
      visibility == :protected
    end

    #: -> bool
    def private?
      visibility == :private
    end
  end

  class Public < Visibility
    #: (?loc: Loc?, ?comments: Array[Comment]) ?{ (Public node) -> void } -> void
    def initialize(loc: nil, comments: [], &block)
      super(:public, loc: loc, comments: comments)
      block&.call(self)
    end
  end

  class Protected < Visibility
    #: (?loc: Loc?, ?comments: Array[Comment]) ?{ (Protected node) -> void } -> void
    def initialize(loc: nil, comments: [], &block)
      super(:protected, loc: loc, comments: comments)
      block&.call(self)
    end
  end

  class Private < Visibility
    #: (?loc: Loc?, ?comments: Array[Comment]) ?{ (Private node) -> void } -> void
    def initialize(loc: nil, comments: [], &block)
      super(:private, loc: loc, comments: comments)
      block&.call(self)
    end
  end

  # Sends

  class Send < NodeWithComments
    #: String
    attr_reader :method

    #: Array[Arg]
    attr_reader :args

    #: (String method, ?Array[Arg] args, ?loc: Loc?, ?comments: Array[Comment]) ?{ (Send node) -> void } -> void
    def initialize(method, args = [], loc: nil, comments: [], &block)
      super(loc: loc, comments: comments)
      @method = method
      @args = args
      block&.call(self)
    end

    #: (Arg arg) -> void
    def <<(arg)
      @args << arg
    end

    #: (Object? other) -> bool
    def ==(other)
      Send === other && method == other.method && args == other.args
    end

    #: -> String
    def to_s
      "#{parent_scope&.fully_qualified_name}.#{method}(#{args.join(", ")})"
    end
  end

  class Arg < Node
    #: String
    attr_reader :value

    #: (String value, ?loc: Loc?) -> void
    def initialize(value, loc: nil)
      super(loc: loc)
      @value = value
    end

    #: (Object? other) -> bool
    def ==(other)
      Arg === other && value == other.value
    end

    #: -> String
    def to_s
      value
    end
  end

  class KwArg < Arg
    #: String
    attr_reader :keyword

    #: (String keyword, String value, ?loc: Loc?) -> void
    def initialize(keyword, value, loc: nil)
      super(value, loc: loc)
      @keyword = keyword
    end

    #: (Object? other) -> bool
    def ==(other)
      KwArg === other && value == other.value && keyword == other.keyword
    end

    #: -> String
    def to_s
      "#{keyword}: #{value}"
    end
  end

  # Sorbet's sigs

  class Sig < NodeWithComments
    #: Array[SigParam]
    attr_reader :params

    #: (Type | String)
    attr_accessor :return_type

    #: bool
    attr_accessor :is_abstract

    #: bool
    attr_accessor :is_override

    #: bool
    attr_accessor :is_overridable

    #: bool
    attr_accessor :is_final

    #: bool
    attr_accessor :allow_incompatible_override

    #: bool
    attr_accessor :allow_incompatible_override_visibility

    #: bool
    attr_accessor :without_runtime

    #: Array[String]
    attr_reader :type_params

    #: Symbol?
    attr_accessor :checked

    #: (
    #|   ?params: Array[SigParam],
    #|   ?return_type: (Type | String),
    #|   ?is_abstract: bool,
    #|   ?is_override: bool,
    #|   ?is_overridable: bool,
    #|   ?is_final: bool,
    #|   ?allow_incompatible_override: bool,
    #|   ?allow_incompatible_override_visibility: bool,
    #|   ?without_runtime: bool,
    #|   ?type_params: Array[String],
    #|   ?checked: Symbol?,
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment]
    #| ) ?{ (Sig node) -> void } -> void
    def initialize(
      params: [],
      return_type: "void",
      is_abstract: false,
      is_override: false,
      is_overridable: false,
      is_final: false,
      allow_incompatible_override: false,
      allow_incompatible_override_visibility: false,
      without_runtime: false,
      type_params: [],
      checked: nil,
      loc: nil,
      comments: [],
      &block
    )
      super(loc: loc, comments: comments)
      @params = params
      @return_type = return_type
      @is_abstract = is_abstract
      @is_override = is_override
      @is_overridable = is_overridable
      @is_final = is_final
      @allow_incompatible_override = allow_incompatible_override
      @allow_incompatible_override_visibility = allow_incompatible_override_visibility
      @without_runtime = without_runtime
      @type_params = type_params
      @checked = checked
      block&.call(self)
    end

    #: (SigParam param) -> void
    def <<(param)
      @params << param
    end

    #: (String name, (Type | String) type) -> void
    def add_param(name, type)
      @params << SigParam.new(name, type)
    end

    #: (Object other) -> bool
    def ==(other)
      return false unless other.is_a?(Sig)

      params == other.params && return_type.to_s == other.return_type.to_s && is_abstract == other.is_abstract &&
        is_override == other.is_override && is_overridable == other.is_overridable && is_final == other.is_final &&
        without_runtime == other.without_runtime && type_params == other.type_params && checked == other.checked
    end
  end

  class SigParam < NodeWithComments
    #: String
    attr_reader :name

    #: (Type | String)
    attr_reader :type

    #: (String name, (Type | String) type, ?loc: Loc?, ?comments: Array[Comment]) ?{ (SigParam node) -> void } -> void
    def initialize(name, type, loc: nil, comments: [], &block)
      super(loc: loc, comments: comments)
      @name = name
      @type = type
      block&.call(self)
    end

    #: (Object other) -> bool
    def ==(other)
      other.is_a?(SigParam) && name == other.name && type.to_s == other.type.to_s
    end
  end

  # Sorbet's T::Struct

  class TStruct < Class
    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) ?{ (TStruct klass) -> void } -> void
    def initialize(name, loc: nil, comments: [], &block)
      super(name, superclass_name: "::T::Struct", loc: loc, comments: comments) {}
      block&.call(self)
    end
  end

  # @abstract
  class TStructField < NodeWithComments
    #: String
    attr_accessor :name

    #: (Type | String)
    attr_accessor :type

    #: String?
    attr_accessor :default

    #: (String name, (Type | String) type, ?default: String?, ?loc: Loc?, ?comments: Array[Comment]) -> void
    def initialize(name, type, default: nil, loc: nil, comments: [])
      super(loc: loc, comments: comments)
      @name = name
      @type = type
      @default = default
    end

    # @abstract
    #: -> Array[String]
    def fully_qualified_names = raise NotImplementedError, "Abstract method called"
  end

  class TStructConst < TStructField
    #: (
    #|   String name,
    #|   (Type | String) type,
    #|   ?default: String?,
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment]
    #| ) ?{ (TStructConst node) -> void } -> void
    def initialize(name, type, default: nil, loc: nil, comments: [], &block)
      super(name, type, default: default, loc: loc, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> Array[String]
    def fully_qualified_names
      parent_name = parent_scope&.fully_qualified_name
      ["#{parent_name}##{name}"]
    end

    # @override
    #: -> String
    def to_s
      "#{parent_scope&.fully_qualified_name}.const(:#{name})"
    end
  end

  class TStructProp < TStructField
    #: (
    #|   String name,
    #|   (Type | String) type,
    #|   ?default: String?,
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment]
    #| ) ?{ (TStructProp node) -> void } -> void
    def initialize(name, type, default: nil, loc: nil, comments: [], &block)
      super(name, type, default: default, loc: loc, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> Array[String]
    def fully_qualified_names
      parent_name = parent_scope&.fully_qualified_name
      ["#{parent_name}##{name}", "#{parent_name}##{name}="]
    end

    # @override
    #: -> String
    def to_s
      "#{parent_scope&.fully_qualified_name}.prop(:#{name})"
    end
  end

  # Sorbet's T::Enum

  class TEnum < Class
    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) ?{ (TEnum klass) -> void } -> void
    def initialize(name, loc: nil, comments: [], &block)
      super(name, superclass_name: "::T::Enum", loc: loc, comments: comments) {}
      block&.call(self)
    end
  end

  class TEnumBlock < Scope
    #: (?loc: Loc?, ?comments: Array[Comment]) ?{ (TEnumBlock node) -> void } -> void
    def initialize(loc: nil, comments: [], &block)
      super {}
      block&.call(self)
    end

    # @override
    #: -> String
    def fully_qualified_name
      "#{parent_scope&.fully_qualified_name}.enums"
    end

    # @override
    #: -> String
    def to_s
      fully_qualified_name
    end
  end

  class TEnumValue < NodeWithComments
    #: String
    attr_reader :name

    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) ?{ (TEnumValue node) -> void } -> void
    def initialize(name, loc: nil, comments: [], &block)
      super(loc: loc, comments: comments)
      @name = name
      block&.call(self)
    end

    #: -> String
    def fully_qualified_name
      "#{parent_scope&.fully_qualified_name}::#{name}"
    end

    # @override
    #: -> String
    def to_s
      fully_qualified_name
    end
  end

  # Sorbet's misc.

  class Helper < NodeWithComments
    #: String
    attr_reader :name

    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) ?{ (Helper node) -> void } -> void
    def initialize(name, loc: nil, comments: [], &block)
      super(loc: loc, comments: comments)
      @name = name
      block&.call(self)
    end

    # @override
    #: -> String
    def to_s
      "#{parent_scope&.fully_qualified_name}.#{name}!"
    end
  end

  class TypeMember < NodeWithComments
    #: String
    attr_reader :name, :value

    #: (String name, String value, ?loc: Loc?, ?comments: Array[Comment]) ?{ (TypeMember node) -> void } -> void
    def initialize(name, value, loc: nil, comments: [], &block)
      super(loc: loc, comments: comments)
      @name = name
      @value = value
      block&.call(self)
    end

    #: -> String
    def fully_qualified_name
      return name if name.start_with?("::")

      "#{parent_scope&.fully_qualified_name}::#{name}"
    end

    # @override
    #: -> String
    def to_s
      fully_qualified_name
    end
  end

  class MixesInClassMethods < Mixin
    #: (
    #|   String name,
    #|   *String names,
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment]
    #| ) ?{ (MixesInClassMethods node) -> void } -> void
    def initialize(name, *names, loc: nil, comments: [], &block)
      super(name, names, loc: loc, comments: comments)
      block&.call(self)
    end

    # @override
    #: -> String
    def to_s
      "#{parent_scope&.fully_qualified_name}.mixes_in_class_methods(#{names.join(", ")})"
    end
  end

  class RequiresAncestor < NodeWithComments
    #: String
    attr_reader :name

    #: (String name, ?loc: Loc?, ?comments: Array[Comment]) -> void
    def initialize(name, loc: nil, comments: [])
      super(loc: loc, comments: comments)
      @name = name
    end

    # @override
    #: -> String
    def to_s
      "#{parent_scope&.fully_qualified_name}.requires_ancestor(#{name})"
    end
  end
end

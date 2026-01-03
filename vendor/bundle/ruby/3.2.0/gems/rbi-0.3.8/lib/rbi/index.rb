# typed: strict
# frozen_string_literal: true

module RBI
  class Index < Visitor
    class << self
      #: (*Node node) -> Index
      def index(*node)
        index = Index.new
        index.visit_all(node)
        index
      end
    end

    #: -> void
    def initialize
      super
      @index = {} #: Hash[String, Array[Node]]
    end

    #: -> Array[String]
    def keys
      @index.keys
    end

    #: (String id) -> Array[Node]
    def [](id)
      @index[id] ||= []
    end

    #: (*Node nodes) -> void
    def index(*nodes)
      nodes.each { |node| visit(node) }
    end

    # @override
    #: (Node? node) -> void
    def visit(node)
      return unless node

      case node
      when Scope
        index_node(node)
        visit_all(node.nodes)
      when Tree
        visit_all(node.nodes)
      when Indexable
        index_node(node)
      end
    end

    private

    #: ((Indexable & Node) node) -> void
    def index_node(node)
      node.index_ids.each { |id| self[id] << node }
    end
  end

  class Tree
    #: -> Index
    def index
      Index.index(self)
    end
  end

  # A Node that can be referred to by a unique ID inside an index
  # @interface
  module Indexable
    # Unique IDs that refer to this node.
    #
    # Some nodes can have multiple ids, for example an attribute accessor matches the ID of the
    # getter and the setter.
    # @abstract
    #: -> Array[String]
    def index_ids = raise NotImplementedError, "Abstract method called"
  end

  class Scope
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      [fully_qualified_name]
    end
  end

  class Const
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      [fully_qualified_name]
    end
  end

  class Attr
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      fully_qualified_names
    end
  end

  class Method
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      [fully_qualified_name]
    end
  end

  class Include
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      names.map { |name| "#{parent_scope&.fully_qualified_name}.include(#{name})" }
    end
  end

  class Extend
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      names.map { |name| "#{parent_scope&.fully_qualified_name}.extend(#{name})" }
    end
  end

  class MixesInClassMethods
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      names.map { |name| "#{parent_scope&.fully_qualified_name}.mixes_in_class_method(#{name})" }
    end
  end

  class RequiresAncestor
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      [to_s]
    end
  end

  class Helper
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      [to_s]
    end
  end

  class TypeMember
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      [to_s]
    end
  end

  class Send
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      ["#{parent_scope&.fully_qualified_name}.#{method}"]
    end
  end

  class TStructConst
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      fully_qualified_names
    end
  end

  class TStructProp
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      fully_qualified_names
    end
  end

  class TEnumBlock
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      [fully_qualified_name]
    end
  end

  class TEnumValue
    include Indexable

    # @override
    #: -> Array[String]
    def index_ids
      [fully_qualified_name]
    end
  end
end

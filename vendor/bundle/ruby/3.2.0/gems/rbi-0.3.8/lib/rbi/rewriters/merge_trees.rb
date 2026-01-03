# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    # Merge two RBI trees together
    #
    # Be this `Tree`:
    # ~~~rb
    # class Foo
    #   attr_accessor :a
    #   def m; end
    #   C = 10
    # end
    # ~~~
    #
    # Merged with this one:
    # ~~~rb
    # class Foo
    #   attr_reader :a
    #   def m(x); end
    #   C = 10
    # end
    # ~~~
    #
    # Compatible definitions are merged together while incompatible definitions are moved into a `ConflictTree`:
    # ~~~rb
    # class Foo
    #   <<<<<<< left
    #   attr_accessor :a
    #   def m; end
    #   =======
    #   attr_reader :a
    #   def m(x); end
    #   >>>>>>> right
    #   C = 10
    # end
    # ~~~
    class Merge
      class Keep
        NONE = new #: Keep
        LEFT = new #: Keep
        RIGHT = new #: Keep

        private_class_method(:new)
      end

      class << self
        #: (Tree left, Tree right, ?left_name: String, ?right_name: String, ?keep: Keep) -> MergeTree
        def merge_trees(left, right, left_name: "left", right_name: "right", keep: Keep::NONE)
          left.nest_singleton_methods!
          right.nest_singleton_methods!
          rewriter = Rewriters::Merge.new(left_name: left_name, right_name: right_name, keep: keep)
          rewriter.merge(left)
          rewriter.merge(right)
          tree = rewriter.tree
          ConflictTreeMerger.new.visit(tree)
          tree
        end
      end

      #: MergeTree
      attr_reader :tree

      #: (?left_name: String, ?right_name: String, ?keep: Keep) -> void
      def initialize(left_name: "left", right_name: "right", keep: Keep::NONE)
        @left_name = left_name
        @right_name = right_name
        @keep = keep
        @tree = MergeTree.new #: MergeTree
        @scope_stack = [@tree] #: Array[Tree]
      end

      #: (Tree tree) -> void
      def merge(tree)
        v = TreeMerger.new(@tree, left_name: @left_name, right_name: @right_name, keep: @keep)
        v.visit(tree)
        @tree.conflicts.concat(v.conflicts)
      end

      # Used for logging / error displaying purpose
      class Conflict
        #: Node
        attr_reader :left, :right

        #: String
        attr_reader :left_name, :right_name

        #: (left: Node, right: Node, left_name: String, right_name: String) -> void
        def initialize(left:, right:, left_name:, right_name:)
          @left = left
          @right = right
          @left_name = left_name
          @right_name = right_name
        end

        #: -> String
        def to_s
          "Conflicting definitions for `#{left}`"
        end
      end

      class TreeMerger < Visitor
        #: Array[Conflict]
        attr_reader :conflicts

        #: (Tree output, ?left_name: String, ?right_name: String, ?keep: Keep) -> void
        def initialize(output, left_name: "left", right_name: "right", keep: Keep::NONE)
          super()
          @tree = output
          @index = output.index #: Index
          @scope_stack = [@tree] #: Array[Tree]
          @left_name = left_name
          @right_name = right_name
          @keep = keep
          @conflicts = [] #: Array[Conflict]
        end

        # @override
        #: (Node? node) -> void
        def visit(node)
          return unless node

          case node
          when Scope
            prev = previous_definition(node)

            if prev.is_a?(Scope)
              if node.compatible_with?(prev)
                prev.merge_with(node)
              elsif @keep == Keep::LEFT
                # do nothing it's already merged
              elsif @keep == Keep::RIGHT
                prev = replace_scope_header(prev, node)
              else
                make_conflict_scope(prev, node)
              end
              @scope_stack << prev
            else
              copy = node.dup_empty
              current_scope << copy
              @scope_stack << copy
            end
            visit_all(node.nodes)
            @scope_stack.pop
          when Tree
            current_scope.merge_with(node)
            visit_all(node.nodes)
          when Indexable
            prev = previous_definition(node)
            if prev
              if node.compatible_with?(prev)
                prev.merge_with(node)
              elsif @keep == Keep::LEFT
                # do nothing it's already merged
              elsif @keep == Keep::RIGHT
                prev.replace(node)
              else
                make_conflict_tree(prev, node)
              end
            else
              current_scope << node.dup
            end
          end
        end

        private

        #: -> Tree
        def current_scope
          @scope_stack.last #: as !nil
        end

        #: (Node node) -> Node?
        def previous_definition(node)
          case node
          when Indexable
            node.index_ids.each do |id|
              others = @index[id]
              return others.last unless others.empty?
            end
          end
          nil
        end

        #: (Scope left, Scope right) -> void
        def make_conflict_scope(left, right)
          @conflicts << Conflict.new(left: left, right: right, left_name: @left_name, right_name: @right_name)
          scope_conflict = ScopeConflict.new(left: left, right: right, left_name: @left_name, right_name: @right_name)
          left.replace(scope_conflict)
        end

        #: (Node left, Node right) -> void
        def make_conflict_tree(left, right)
          @conflicts << Conflict.new(left: left, right: right, left_name: @left_name, right_name: @right_name)
          tree = left.parent_conflict_tree
          unless tree
            tree = ConflictTree.new(left_name: @left_name, right_name: @right_name)
            left.replace(tree)
            tree.left << left
          end
          tree.right << right
        end

        #: (Scope left, Scope right) -> Scope
        def replace_scope_header(left, right)
          right_copy = right.dup_empty
          left.replace(right_copy)
          left.nodes.each do |node|
            right_copy << node
          end
          @index.index(right_copy)
          right_copy
        end
      end

      # Merge adjacent conflict trees
      #
      # Transform this:
      # ~~~rb
      # class Foo
      #   <<<<<<< left
      #   def m1; end
      #   =======
      #   def m1(a); end
      #   >>>>>>> right
      #   <<<<<<< left
      #   def m2(a); end
      #   =======
      #   def m2; end
      #   >>>>>>> right
      # end
      # ~~~
      #
      # Into this:
      # ~~~rb
      # class Foo
      #   <<<<<<< left
      #   def m1; end
      #   def m2(a); end
      #   =======
      #   def m1(a); end
      #   def m2; end
      #   >>>>>>> right
      # end
      # ~~~
      class ConflictTreeMerger < Visitor
        # @override
        #: (Node? node) -> void
        def visit(node)
          visit_all(node.nodes) if node.is_a?(Tree)
        end

        # @override
        #: (Array[Node] nodes) -> void
        def visit_all(nodes)
          last_conflict_tree = nil #: ConflictTree?
          nodes.dup.each do |node|
            if node.is_a?(ConflictTree)
              if last_conflict_tree
                merge_conflict_trees(last_conflict_tree.left, node.left)
                merge_conflict_trees(last_conflict_tree.right, node.right)
                node.detach
                next
              else
                last_conflict_tree = node
              end
            end

            visit(node)
          end
        end

        private

        #: (Tree left, Tree right) -> void
        def merge_conflict_trees(left, right)
          right.nodes.dup.each do |node|
            left << node
          end
        end
      end
    end
  end

  class Node
    # Can `self` and `_other` be merged into a single definition?
    #: (Node _other) -> bool
    def compatible_with?(_other)
      true
    end

    # Merge `self` and `other` into a single definition
    #: (Node other) -> void
    def merge_with(other); end

    #: -> ConflictTree?
    def parent_conflict_tree
      parent = parent_tree #: Node?
      while parent
        return parent if parent.is_a?(ConflictTree)

        parent = parent.parent_tree
      end
      nil
    end
  end

  class NodeWithComments
    # @override
    #: (Node other) -> void
    def merge_with(other)
      return unless other.is_a?(NodeWithComments)

      other.comments.each do |comment|
        comments << comment unless comments.include?(comment)
      end
    end
  end

  class Tree
    #: (Tree other, ?left_name: String, ?right_name: String, ?keep: Rewriters::Merge::Keep) -> MergeTree
    def merge(other, left_name: "left", right_name: "right", keep: Rewriters::Merge::Keep::NONE)
      Rewriters::Merge.merge_trees(self, other, left_name: left_name, right_name: right_name, keep: keep)
    end
  end

  # A tree that _might_ contain conflicts
  class MergeTree < Tree
    #: Array[Rewriters::Merge::Conflict]
    attr_reader :conflicts

    #: (
    #|   ?loc: Loc?,
    #|   ?comments: Array[Comment],
    #|   ?conflicts: Array[Rewriters::Merge::Conflict]
    #| ) ?{ (Tree node) -> void } -> void
    def initialize(loc: nil, comments: [], conflicts: [], &block)
      super(loc: loc, comments: comments)
      @conflicts = conflicts
      block&.call(self)
    end
  end

  class DuplicateNodeError < Error; end

  class Scope
    # Duplicate `self` scope without its body
    #: -> self
    def dup_empty
      case self
      when Module
        Module.new(name, loc: loc, comments: comments)
      when TEnum
        TEnum.new(name, loc: loc, comments: comments)
      when TEnumBlock
        TEnumBlock.new(loc: loc, comments: comments)
      when TStruct
        TStruct.new(name, loc: loc, comments: comments)
      when Class
        Class.new(name, superclass_name: superclass_name, loc: loc, comments: comments)
      when Struct
        Struct.new(name, members: members, keyword_init: keyword_init, loc: loc, comments: comments)
      when SingletonClass
        SingletonClass.new(loc: loc, comments: comments)
      else
        raise DuplicateNodeError, "Can't duplicate node #{self}"
      end
    end
  end

  class Class
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(Class) && superclass_name == other.superclass_name
    end
  end

  class Module
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(Module)
    end
  end

  class Struct
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(Struct) && members == other.members && keyword_init == other.keyword_init
    end
  end

  class Const
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(Const) && name == other.name && value == other.value
    end
  end

  class Attr
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      return false unless other.is_a?(Attr)
      return false unless names == other.names

      sigs.empty? || other.sigs.empty? || sigs == other.sigs
    end

    # @override
    #: (Node other) -> void
    def merge_with(other)
      return unless other.is_a?(Attr)

      super
      other.sigs.each do |sig|
        sigs << sig unless sigs.include?(sig)
      end
    end
  end

  class AttrReader
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(AttrReader) && super
    end
  end

  class AttrWriter
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(AttrWriter) && super
    end
  end

  class AttrAccessor
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(AttrAccessor) && super
    end
  end

  class Method
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      return false unless other.is_a?(Method)
      return false unless name == other.name
      return false unless params == other.params

      sigs.empty? || other.sigs.empty? || sigs == other.sigs
    end

    # @override
    #: (Node other) -> void
    def merge_with(other)
      return unless other.is_a?(Method)

      super
      other.sigs.each do |sig|
        sigs << sig unless sigs.include?(sig)
      end
    end
  end

  class Mixin
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(Mixin) && names == other.names
    end
  end

  class Include
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(Include) && super
    end
  end

  class Extend
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(Extend) && super
    end
  end

  class MixesInClassMethods
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(MixesInClassMethods) && super
    end
  end

  class Helper
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(Helper) && name == other.name
    end
  end

  class Send
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(Send) && method == other.method && args == other.args
    end
  end

  class TStructField
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(TStructField) && name == other.name && type == other.type && default == other.default
    end
  end

  class TStructConst
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(TStructConst) && super
    end
  end

  class TStructProp
    # @override
    #: (Node other) -> bool
    def compatible_with?(other)
      other.is_a?(TStructProp) && super
    end
  end

  # A tree showing incompatibles nodes
  #
  # Is rendered as a merge conflict between `left` and` right`:
  # ~~~rb
  # class Foo
  #   <<<<<<< left
  #   def m1; end
  #   def m2(a); end
  #   =======
  #   def m1(a); end
  #   def m2; end
  #   >>>>>>> right
  # end
  # ~~~
  class ConflictTree < Tree
    #: Tree
    attr_reader :left, :right

    #: String
    attr_reader :left_name, :right_name

    #: (?left_name: String, ?right_name: String) -> void
    def initialize(left_name: "left", right_name: "right")
      super()
      @left_name = left_name
      @right_name = right_name
      @left = Tree.new #: Tree
      @left.parent_tree = self
      @right = Tree.new #: Tree
      @right.parent_tree = self
    end
  end

  # A conflict between two scope headers
  #
  # Is rendered as a merge conflict between `left` and` right` for scope definitions:
  # ~~~rb
  # <<<<<<< left
  # class Foo
  # =======
  # module Foo
  # >>>>>>> right
  #   def m1; end
  # end
  # ~~~
  class ScopeConflict < Tree
    #: Scope
    attr_reader :left, :right

    #: String
    attr_reader :left_name, :right_name

    #: (left: Scope, right: Scope, ?left_name: String, ?right_name: String) -> void
    def initialize(left:, right:, left_name: "left", right_name: "right")
      super()
      @left = left
      @right = right
      @left_name = left_name
      @right_name = right_name
    end
  end
end

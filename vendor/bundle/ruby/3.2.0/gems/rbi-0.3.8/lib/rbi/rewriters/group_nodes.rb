# typed: strict
# frozen_string_literal: true

module RBI
  class GroupNodesError < Error; end

  module Rewriters
    class GroupNodes < Visitor
      # @override
      #: (Node? node) -> void
      def visit(node)
        return unless node

        case node
        when Tree
          kinds = node.nodes.map { |child| group_kind(child) }
          kinds.uniq!

          groups = {}
          kinds.each { |kind| groups[kind] = Group.new(kind) }

          node.nodes.dup.each do |child|
            visit(child)
            child.detach
            groups[group_kind(child)] << child
          end

          groups.each { |_, group| node << group }
        end
      end

      private

      #: (Node node) -> Group::Kind
      def group_kind(node)
        case node
        when Group
          node.kind
        when Include, Extend
          Group::Kind::Mixins
        when RequiresAncestor
          Group::Kind::RequiredAncestors
        when Helper
          Group::Kind::Helpers
        when TypeMember
          Group::Kind::TypeMembers
        when MixesInClassMethods
          Group::Kind::MixesInClassMethods
        when Send
          Group::Kind::Sends
        when Attr
          Group::Kind::Attrs
        when TStructField
          Group::Kind::TStructFields
        when TEnumBlock
          Group::Kind::TEnums
        when VisibilityGroup
          Group::Kind::Methods
        when Method
          if node.name == "initialize"
            Group::Kind::Inits
          else
            Group::Kind::Methods
          end
        when SingletonClass
          Group::Kind::SingletonClasses
        when Scope, Const
          Group::Kind::Consts
        else
          raise GroupNodesError, "Unknown group for #{self}"
        end
      end
    end
  end

  class Tree
    #: -> void
    def group_nodes!
      visitor = Rewriters::GroupNodes.new
      visitor.visit(self)
    end
  end

  class Group < Tree
    #: Kind
    attr_reader :kind

    #: (Kind kind) -> void
    def initialize(kind)
      super()
      @kind = kind
    end

    class Kind
      Mixins              = new #: Kind
      RequiredAncestors   = new #: Kind
      Helpers             = new #: Kind
      TypeMembers         = new #: Kind
      MixesInClassMethods = new #: Kind
      Sends               = new #: Kind
      Attrs               = new #: Kind
      TStructFields       = new #: Kind
      TEnums              = new #: Kind
      Inits               = new #: Kind
      Methods             = new #: Kind
      SingletonClasses    = new #: Kind
      Consts              = new #: Kind

      private_class_method(:new)
    end
  end
end

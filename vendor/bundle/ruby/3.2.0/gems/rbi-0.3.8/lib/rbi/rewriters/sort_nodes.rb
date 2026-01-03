# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    class SortNodes < Visitor
      # @override
      #: (Node? node) -> void
      def visit(node)
        sort_node_names!(node) if node

        return unless node.is_a?(Tree)

        visit_all(node.nodes)
        original_order = node.nodes.map.with_index.to_h

        # The child nodes could contain private/protected markers. If so, they should not be moved in the file.
        # Otherwise, some methods could see their privacy change. To avoid that problem, divide the array of child
        # nodes into chunks based on whether any Visibility nodes appear, and sort the chunks independently. This
        # applies the ordering rules from the node_rank method as much as possible, while preserving visibility.
        sorted_nodes = node.nodes.chunk do |n|
          n.is_a?(Visibility)
        end.flat_map do |_, nodes|
          nodes.sort! do |a, b|
            # First we try to compare the nodes by their node rank (based on the node type)
            res = node_rank(a) <=> node_rank(b)
            next res if res != 0 # we can sort the nodes by their rank, let's stop here

            # Then, if the nodes ranks are the same (res == 0), we try to compare the nodes by their name
            res = node_name(a) <=> node_name(b)
            next res if res && res != 0 # we can sort the nodes by their name, let's stop here

            # Finally, if the two nodes have the same rank and the same name or at least one node is anonymous then,
            original_order_a = original_order[a] #: as !nil
            original_order_b = original_order[b] #: as !nil
            original_order_a <=> original_order_b # we keep the original order
          end
        end

        node.nodes.replace(sorted_nodes)
      end

      private

      #: (Node node) -> Integer
      def node_rank(node)
        case node
        when Group                then group_rank(node.kind)
        when Include, Extend      then 10
        when RequiresAncestor     then 15
        when Helper               then 20
        when TypeMember           then 30
        when MixesInClassMethods  then 40
        when Send                 then 50
        when TStructField         then 60
        when TEnumBlock           then 70
        when Attr                 then 75
        when Method
          if node.name == "initialize"
            81
          elsif !node.is_singleton
            82
          else
            83
          end
        when SingletonClass       then 90
        when Scope, Const         then 100
        else
          110
        end
      end

      #: (Group::Kind kind) -> Integer
      def group_rank(kind)
        case kind
        when Group::Kind::Mixins              then 0
        when Group::Kind::RequiredAncestors   then 1
        when Group::Kind::Helpers             then 2
        when Group::Kind::TypeMembers         then 3
        when Group::Kind::MixesInClassMethods then 4
        when Group::Kind::Sends               then 5
        when Group::Kind::TStructFields       then 6
        when Group::Kind::TEnums              then 7
        when Group::Kind::Attrs               then 8
        when Group::Kind::Inits               then 9
        when Group::Kind::Methods             then 10
        when Group::Kind::SingletonClasses    then 11
        when Group::Kind::Consts              then 12
        else
          raise Error, "Unknown group kind: #{kind}"
        end
      end

      #: (Node node) -> String?
      def node_name(node)
        case node
        when Module, Class, Struct, Const, Method, Helper, RequiresAncestor
          node.name
        when Attr
          node.names.first.to_s
        when TStructField, Mixin
          nil # we never want to sort these nodes by their name
        end
      end

      #: (Node node) -> void
      def sort_node_names!(node)
        case node
        when Attr
          node.names.sort!
        end
      end
    end
  end

  class Tree
    #: -> void
    def sort_nodes!
      visitor = Rewriters::SortNodes.new
      visitor.visit(self)
    end
  end
end

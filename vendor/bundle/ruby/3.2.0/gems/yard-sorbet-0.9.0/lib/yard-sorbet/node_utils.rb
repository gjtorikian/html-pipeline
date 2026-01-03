# typed: strict
# frozen_string_literal: true

module YARDSorbet
  # Helper methods for working with `YARD` AST Nodes
  module NodeUtils
    extend T::Sig

    # Command node types that can have type signatures
    ATTRIBUTE_METHODS = T.let(%i[attr attr_accessor attr_reader attr_writer].freeze, T::Array[Symbol])
    # Skip these method contents during BFS node traversal, they can have their own nested types via `T.Proc`
    SKIP_METHOD_CONTENTS = T.let(%i[params returns].freeze, T::Array[Symbol])
    # Node types that can have type signatures
    SigableNode = T.type_alias { T.any(YARD::Parser::Ruby::MethodDefinitionNode, YARD::Parser::Ruby::MethodCallNode) }
    private_constant :ATTRIBUTE_METHODS, :SKIP_METHOD_CONTENTS, :SigableNode

    # Traverse AST nodes in breadth-first order
    # @note This will skip over some node types.
    # @yield [YARD::Parser::Ruby::AstNode]
    sig { params(node: YARD::Parser::Ruby::AstNode, _blk: T.proc.params(n: YARD::Parser::Ruby::AstNode).void).void }
    def self.bfs_traverse(node, &_blk)
      queue = Queue.new << node
      until queue.empty?
        n = queue.deq(true)
        yield n
        enqueue_children(queue, n)
      end
    end

    sig { params(node: YARD::Parser::Ruby::AstNode).void }
    def self.delete_node(node) = node.parent.children.delete(node)

    # Enqueue the eligible children of a node in the BFS queue
    sig { params(queue: Queue, node: YARD::Parser::Ruby::AstNode).void }
    def self.enqueue_children(queue, node)
      last_child = node.children.last
      node.children.each do |child|
        next if child == last_child &&
                node.is_a?(YARD::Parser::Ruby::MethodCallNode) &&
                SKIP_METHOD_CONTENTS.include?(node.method_name(true))

        queue.enq(child)
      end
    end

    # Gets the node that a sorbet `sig` can be attached do, bypassing visisbility modifiers and the like
    sig { params(node: YARD::Parser::Ruby::AstNode).returns(SigableNode) }
    def self.get_method_node(node) = sigable_node?(node) ? node : node.jump(:def, :defs)

    # Find and return the adjacent node (ascending)
    # @raise [IndexError] if the node does not have an adjacent sibling (ascending)
    sig { params(node: YARD::Parser::Ruby::AstNode).returns(YARD::Parser::Ruby::AstNode) }
    def self.sibling_node(node)
      siblings = node.parent.children
      node_index = siblings.find_index { _1.equal?(node) }
      siblings.fetch(node_index + 1)
    end

    sig { params(node: YARD::Parser::Ruby::AstNode).returns(T::Boolean) }
    def self.sigable_node?(node)
      case node
      when YARD::Parser::Ruby::MethodDefinitionNode then true
      when YARD::Parser::Ruby::MethodCallNode then ATTRIBUTE_METHODS.include?(node.method_name(true))
      else false
      end
    end

    # @see https://github.com/lsegal/yard/blob/main/lib/yard/handlers/ruby/attribute_handler.rb
    #   YARD::Handlers::Ruby::AttributeHandler.validated_attribute_names
    sig { params(attr_node: YARD::Parser::Ruby::MethodCallNode).returns(T::Array[String]) }
    def self.validated_attribute_names(attr_node)
      attr_node.parameters(false).map do |obj|
        case obj
        when YARD::Parser::Ruby::LiteralNode then obj[0][0].source
        else raise YARD::Parser::UndocumentableError, obj.source
        end
      end
    end
  end
end

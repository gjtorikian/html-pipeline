# typed: strict
# frozen_string_literal: true

module Spoom
  # Build a file hierarchy from a set of file paths.
  class FileTree
    #: (?T::Enumerable[String] paths) -> void
    def initialize(paths = [])
      @roots = {} #: Hash[String, Node]
      add_paths(paths)
    end

    # Add all `paths` to the tree
    #: (T::Enumerable[String] paths) -> void
    def add_paths(paths)
      paths.each { |path| add_path(path) }
    end

    # Add a `path` to the tree
    #
    # This will create all nodes until the root of `path`.
    #: (String path) -> Node
    def add_path(path)
      parts = path.split("/")
      if path.empty? || parts.size == 1
        return @roots[path] ||= Node.new(parent: nil, name: path)
      end

      parent_path = T.must(parts[0...-1]).join("/")
      parent = add_path(parent_path)
      name = T.must(parts.last)
      parent.children[name] ||= Node.new(parent: parent, name: name)
    end

    # All root nodes
    #: -> Array[Node]
    def roots
      @roots.values
    end

    # All the nodes in this tree
    #: -> Array[Node]
    def nodes
      v = CollectNodes.new
      v.visit_tree(self)
      v.nodes
    end

    # All the paths in this tree
    #: -> Array[String]
    def paths
      nodes.map(&:path)
    end

    # Return a map of typing scores for each node in the tree
    #: (Context context) -> Hash[Node, Float]
    def nodes_strictness_scores(context)
      v = CollectScores.new(context)
      v.visit_tree(self)
      v.scores
    end

    # Return a map of typing scores for each path in the tree
    #: (Context context) -> Hash[String, Float]
    def paths_strictness_scores(context)
      nodes_strictness_scores(context).map { |node, score| [node.path, score] }.to_h
    end

    #: (?out: (IO | StringIO), ?colors: bool) -> void
    def print(out: $stdout, colors: true)
      printer = Printer.new({}, out: out, colors: colors)
      printer.visit_tree(self)
    end

    # A node representing either a file or a directory inside a FileTree
    class Node < T::Struct
      # Node parent or `nil` if the node is a root one
      const :parent, T.nilable(Node)

      # File or dir name
      const :name, String

      # Children of this node (if not empty, it means it's a dir)
      const :children, T::Hash[String, Node], default: {}

      # Full path to this node from root
      #: -> String
      def path
        parent = self.parent
        return name unless parent

        "#{parent.path}/#{name}"
      end
    end

    # An abstract visitor for FileTree
    class Visitor
      extend T::Helpers

      abstract!

      #: (FileTree tree) -> void
      def visit_tree(tree)
        visit_nodes(tree.roots)
      end

      #: (FileTree::Node node) -> void
      def visit_node(node)
        visit_nodes(node.children.values)
      end

      #: (Array[FileTree::Node] nodes) -> void
      def visit_nodes(nodes)
        nodes.each { |node| visit_node(node) }
      end
    end

    # A visitor that collects all the nodes in a tree
    class CollectNodes < Visitor
      #: Array[FileTree::Node]
      attr_reader :nodes

      #: -> void
      def initialize
        super()
        @nodes = [] #: Array[FileTree::Node]
      end

      # @override
      #: (FileTree::Node node) -> void
      def visit_node(node)
        @nodes << node
        super
      end
    end

    # A visitor that collects the strictness of each node in a tree
    class CollectStrictnesses < Visitor
      #: Hash[Node, String?]
      attr_reader :strictnesses

      #: (Context context) -> void
      def initialize(context)
        super()
        @context = context
        @strictnesses = {} #: Hash[Node, String?]
      end

      # @override
      #: (FileTree::Node node) -> void
      def visit_node(node)
        path = node.path
        @strictnesses[node] = @context.read_file_strictness(path) if @context.file?(path)

        super
      end
    end

    # A visitor that collects the typing score of each node in a tree
    class CollectScores < CollectStrictnesses
      #: Hash[Node, Float]
      attr_reader :scores

      #: (Context context) -> void
      def initialize(context)
        super
        @context = context
        @scores = {} #: Hash[Node, Float]
      end

      # @override
      #: (FileTree::Node node) -> void
      def visit_node(node)
        super

        @scores[node] = node_score(node)
      end

      private

      #: (Node node) -> Float
      def node_score(node)
        if @context.file?(node.path)
          strictness_score(@strictnesses[node])
        else
          node.children.values.sum { |child| @scores.fetch(child, 0.0) } / node.children.size.to_f
        end
      end

      #: (String? strictness) -> Float
      def strictness_score(strictness)
        case strictness
        when "true", "strict", "strong"
          1.0
        else
          0.0
        end
      end
    end

    # An internal class used to print a FileTree
    #
    # See `FileTree#print`
    class Printer < Visitor
      #: (Hash[FileTree::Node, String?] strictnesses, ?out: (IO | StringIO), ?colors: bool) -> void
      def initialize(strictnesses, out: $stdout, colors: true)
        super()
        @strictnesses = strictnesses
        @colors = colors
        @printer = Spoom::Printer.new(out: out, colors: colors) #: Spoom::Printer
      end

      # @override
      #: (FileTree::Node node) -> void
      def visit_node(node)
        @printer.printt
        if node.children.empty?
          strictness = @strictnesses[node]
          if @colors
            @printer.print_colored(node.name, strictness_color(strictness))
          elsif strictness
            @printer.print("#{node.name} (#{strictness})")
          else
            @printer.print(node.name.to_s)
          end
          @printer.print("\n")
        else
          @printer.print_colored(node.name, Color::BLUE)
          @printer.print("/")
          @printer.printn
          @printer.indent
          super
          @printer.dedent
        end
      end

      private

      #: (String? strictness) -> Color
      def strictness_color(strictness)
        case strictness
        when "false"
          Color::RED
        when "true", "strict", "strong"
          Color::GREEN
        else
          Color::CLEAR
        end
      end
    end
  end
end

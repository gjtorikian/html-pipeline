# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Remover
      class Error < Spoom::Error; end

      #: (Context context) -> void
      def initialize(context)
        @context = context
      end

      #: (Definition::Kind? kind, Location location) -> String
      def remove_location(kind, location)
        file = location.file

        unless @context.file?(file)
          raise Error, "Can't find file at #{file}"
        end

        node_remover = NodeRemover.new(@context.read(file), kind, location)
        node_remover.apply_edit
        node_remover.new_source
      end

      class NodeRemover
        #: String
        attr_reader :new_source

        #: (String source, Definition::Kind? kind, Location location) -> void
        def initialize(source, kind, location)
          @old_source = source
          @new_source = source.dup #: String
          @kind = kind
          @location = location

          @node_context = NodeFinder.find(source, location, kind) #: NodeContext
        end

        #: -> void
        def apply_edit
          sclass_context = @node_context.sclass_context
          if sclass_context
            delete_node_and_comments_and_sigs(sclass_context)
            return
          end

          node = @node_context.node
          case node
          when Prism::ClassNode, Prism::ModuleNode, Prism::DefNode
            delete_node_and_comments_and_sigs(@node_context)
          when Prism::ConstantWriteNode, Prism::ConstantOperatorWriteNode,
                Prism::ConstantAndWriteNode, Prism::ConstantOrWriteNode,
                Prism::ConstantPathWriteNode, Prism::ConstantPathOperatorWriteNode,
                Prism::ConstantPathAndWriteNode, Prism::ConstantPathOrWriteNode,
                Prism::ConstantTargetNode
            delete_constant_assignment(@node_context)
          when Prism::SymbolNode # for attr accessors
            delete_attr_accessor(@node_context)
          else
            raise Error, "Unsupported node type: #{node.class}"
          end
        end

        private

        #: (NodeContext context) -> void
        def delete_constant_assignment(context)
          case context.node
          when Prism::ConstantWriteNode, Prism::ConstantOperatorWriteNode,
               Prism::ConstantAndWriteNode, Prism::ConstantOrWriteNode,
               Prism::ConstantPathWriteNode, Prism::ConstantPathOperatorWriteNode,
               Prism::ConstantPathAndWriteNode, Prism::ConstantPathOrWriteNode
            # Nesting node is an assign, it means only one constant is assigned on the line
            # so we can remove the whole assign
            delete_node_and_comments_and_sigs(context)
            return
          end

          # We're assigning multiple constants, we need to remove only the useless node
          parent_context = context.parent_context
          parent_node = parent_context.node
          if parent_node.is_a?(Prism::ConstantWriteNode)
            # Nesting node is an assign, it means only one constant is assigned on the line
            # so we can remove the whole assign
            delete_node_and_comments_and_sigs(parent_context)
            return
          elsif parent_node.is_a?(Prism::MultiWriteNode) && parent_node.lefts.size == 1
            # Nesting node is a single left hand side, it means only one constant is assigned
            # so we can remove the whole line
            delete_node_and_comments_and_sigs(parent_context.parent_context)
            return
          end

          # Nesting node is a multiple left hand side, it means multiple constants are assigned
          # so we need to remove only the right node from the left hand side
          node = context.node
          prev_node = context.previous_node
          next_node = context.next_node

          has_prev_node_on_different_line = prev_node && prev_node.location.end_line != node.location.start_line
          has_next_node_on_different_line = next_node && next_node.location.start_line != node.location.end_line

          if has_prev_node_on_different_line && has_next_node_on_different_line
            # We have a node before and after, but on different lines, we need to remove the whole line
            #
            # ~~~
            # FOO,
            # BAR, # we need to remove BAR
            # BAZ = 42
            # ~~~
            delete_lines(node.location.start_line, node.location.end_line)
          elsif prev_node && next_node.is_a?(Prism::ConstantTargetNode)
            # We have a node before and after one the same line, just remove the part of the line
            #
            # ~~~
            # FOO, BAR, BAZ = 42 # we need to remove BAR
            # ~~~
            replace_chars(prev_node.location.end_offset, next_node.location.start_offset, ", ")
          elsif prev_node
            # We have a node before, on the same line, but no node after, just remove the part of the line
            #
            # ~~~
            # FOO, BAR = 42 # we need to remove BAR
            # ~~~
            nesting_assign = T.cast(parent_context.node, Prism::MultiWriteNode)

            rparen_loc = nesting_assign.rparen_loc
            if rparen_loc
              # We have an assign with parenthesis, we need to remove the part of the line until the closing parenthesis
              delete_chars(prev_node.location.end_offset, rparen_loc.start_offset)
            else
              # We don't have a parenthesis, we need to remove the part of the line until the operator
              replace_chars(prev_node.location.end_offset, nesting_assign.operator_loc.start_offset, " ")
            end
          elsif next_node.is_a?(Prism::ConstantTargetNode)
            # We don't have a node before but a node after on the same line, just remove the part of the line
            #
            # ~~~
            # FOO, BAR = 42 # we need to remove FOO
            # ~~~
            delete_chars(node.location.start_offset, next_node.location.start_offset)
          else
            # Should have been removed as a single MLHS node
            raise Error, "Unexpected case while removing constant assignment"
          end
        end

        #: (NodeContext context) -> void
        def delete_attr_accessor(context)
          args_context = context.parent_context
          send_context = args_context.parent_context
          send_context = send_context.parent_context if send_context.node.is_a?(Prism::ArgumentsNode)

          send_node = T.cast(send_context.node, Prism::CallNode)
          need_accessor = send_node.name == :attr_accessor

          if args_context.node.child_nodes.size == 1
            # Only one accessor is defined, we can remove the whole node
            delete_node_and_comments_and_sigs(send_context)
            insert_accessor(context.node, send_context, was_removed: true) if need_accessor
            return
          end

          prev_node = context.previous_node
          next_node = context.next_node

          has_prev_node_on_different_line = prev_node && prev_node.location.end_line != context.node.location.start_line
          has_next_node_on_different_line = next_node && next_node.location.start_line != context.node.location.end_line

          if has_prev_node_on_different_line && has_next_node_on_different_line
            # We have a node before and after, but on different lines, we need to remove the whole line
            #
            # ~~~
            # attr_reader(
            #  :foo,
            #  :bar, # attr to remove
            #  :baz,
            # )
            # ~~~
            delete_lines(context.node.location.start_line, context.node.location.end_line)
          elsif prev_node && next_node
            # We have a node before and after one the same line, just remove the part of the line
            #
            # ~~~
            # attr_reader :foo, :bar, :baz # we need to remove bar
            # ~~~
            replace_chars(prev_node.location.end_offset, next_node.location.start_offset, ", ")
          elsif prev_node
            # We have a node before, on the same line, but no node after, just remove the part of the line
            #
            # ~~~
            # attr_reader :foo, :bar, :baz # we need to remove baz
            # ~~~
            delete_chars(prev_node.location.end_offset, context.node.location.end_offset)
          elsif next_node
            # We don't have a node before but a node after on the same line, just remove the part of the line
            #
            # ~~~
            # attr_reader :foo, :bar, :baz # we need to remove foo
            # ~~~
            delete_chars(context.node.location.start_offset, next_node.location.start_offset)
          else
            raise Error, "Unexpected case while removing attr_accessor"
          end

          insert_accessor(context.node, send_context, was_removed: false) if need_accessor
        end

        #: (Prism::Node node, NodeContext send_context, was_removed: bool) -> void
        def insert_accessor(node, send_context, was_removed:)
          name = node.slice
          code = case @kind
          when Definition::Kind::AttrReader
            "attr_writer #{name}"
          when Definition::Kind::AttrWriter
            "attr_reader #{name}"
          end

          indent = " " * send_context.node.location.start_column

          sig = send_context.attached_sig
          sig_string = transform_sig(sig, name: name, kind: @kind) if sig

          node_after = send_context.next_node

          if was_removed
            first_node = send_context.attached_sigs.first || send_context.node
            at_line = first_node.location.start_line - 1

            prev_context = NodeContext.new(@old_source, @node_context.comments, first_node, send_context.nesting)
            node_before = prev_context.previous_node

            new_line_before = node_before && send_context.node.location.start_line - node_before.location.end_line < 2
            new_line_after = node_after && node_after.location.start_line - send_context.node.location.end_line <= 2
          else
            at_line = send_context.node.location.end_line
            new_line_before = true
            new_line_after = node_after && node_after.location.start_line - send_context.node.location.end_line < 2
          end

          lines_to_insert = String.new
          lines_to_insert << "\n" if new_line_before
          lines_to_insert << "#{indent}#{sig_string}\n" if sig_string
          lines_to_insert << "#{indent}#{code}\n"
          lines_to_insert << "\n" if new_line_after

          lines = @new_source.lines
          lines.insert(at_line, lines_to_insert)
          @new_source = lines.join
        end

        #: (NodeContext context) -> void
        def delete_node_and_comments_and_sigs(context)
          start_line = context.node.location.start_line
          end_line = context.node.location.end_line

          # TODO: remove once Prism location are fixed
          node = context.node
          case node
          when Prism::ConstantWriteNode, Prism::ConstantOperatorWriteNode,
                Prism::ConstantAndWriteNode, Prism::ConstantOrWriteNode,
                Prism::ConstantPathWriteNode, Prism::ConstantPathOperatorWriteNode,
                Prism::ConstantPathAndWriteNode, Prism::ConstantPathOrWriteNode
            value = node.value
            if value.is_a?(Prism::StringNode)
              end_line = value.closing_loc&.start_line || value.location.end_line
            end
          end

          # Adjust the lines to remove to include sigs attached to the node
          first_node = context.attached_sigs.first || context.node
          start_line = first_node.location.start_line if first_node

          # Adjust the lines to remove to include comments attached to the node
          first_comment = context.attached_comments(first_node).first
          start_line = first_comment.location.start_line if first_comment

          # Adjust the lines to remove to include previous blank lines
          prev_context = NodeContext.new(@old_source, @node_context.comments, first_node, context.nesting)
          before = prev_context.previous_node #: (Prism::Node | Prism::Comment)?

          # There may be an unrelated comment between the current node and the one before
          # if there is, we only want to delete lines up to the last comment found
          if before
            to_node = first_comment || node
            comment = @node_context.comments_between_lines(before.location.end_line, to_node.location.start_line).last
            before = comment if comment
          end

          if before && before.location.end_line < start_line - 1
            # There is a node before and a blank line
            start_line = before.location.end_line + 1
          elsif before.nil?
            # There is no node before, check if there is a blank line
            parent_context = context.parent_context
            # With Prism the StatementsNode location starts at the first line of the first node
            parent_context = parent_context.parent_context if parent_context.node.is_a?(Prism::StatementsNode)
            if parent_context.node.location.start_line < start_line - 1
              # There is a blank line before the node
              start_line = parent_context.node.location.start_line + 1
            end
          end

          # Adjust the lines to remove to include following blank lines
          after = context.next_node
          if before.nil? && after && after.location.start_line > end_line + 1
            end_line = after.location.start_line - 1
          elsif after.nil? && context.parent_node.location.end_line > end_line + 1
            end_line = context.parent_node.location.end_line - 1
          end

          delete_lines(start_line, end_line)
        end

        #: (Integer start_line, Integer end_line) -> void
        def delete_lines(start_line, end_line)
          lines = @new_source.lines
          lines[start_line - 1...end_line] = []
          @new_source = lines.join
        end

        #: (Integer start_char, Integer end_char) -> void
        def delete_chars(start_char, end_char)
          @new_source[start_char...end_char] = ""
        end

        #: (Integer start_char, Integer end_char, String replacement) -> void
        def replace_chars(start_char, end_char, replacement)
          @new_source[start_char...end_char] = replacement
        end

        #: (Prism::CallNode node, name: String, kind: Definition::Kind?) -> String
        def transform_sig(node, name:, kind:)
          type = nil #: String?

          block = T.cast(node.block, Prism::BlockNode)
          statements = T.cast(block.body, Prism::StatementsNode)

          statements.body.each do |call|
            next unless call.is_a?(Prism::CallNode)
            next unless call.name == :returns

            args = call.arguments
            next unless args

            first = args.arguments.first
            next unless first

            type = first.slice
          end

          name = name.delete_prefix(":")
          type = T.must(type)

          case kind
          when Definition::Kind::AttrReader
            "sig { params(#{name}: #{type}).returns(#{type}) }"
          else
            "sig { returns(#{type}) }"
          end
        end
      end

      class NodeContext
        #: Hash[Integer, Prism::Comment]
        attr_reader :comments

        #: Prism::Node
        attr_reader :node

        #: Array[Prism::Node]
        attr_accessor :nesting

        #: (String source, Hash[Integer, Prism::Comment] comments, Prism::Node node, Array[Prism::Node] nesting) -> void
        def initialize(source, comments, node, nesting)
          @source = source
          @comments = comments
          @node = node
          @nesting = nesting
        end

        #: -> Prism::Node
        def parent_node
          parent = @nesting.last
          raise Error, "No parent for node #{node}" unless parent

          parent
        end

        #: -> NodeContext
        def parent_context
          nesting = @nesting.dup
          parent = nesting.pop
          raise Error, "No parent context for node #{@node}" unless parent

          NodeContext.new(@source, @comments, parent, nesting)
        end

        #: -> Array[Prism::Node]
        def previous_nodes
          parent = parent_node
          child_nodes = parent.child_nodes.compact

          index = child_nodes.index(@node)
          raise Error, "Node #{@node} not found in parent #{parent}" unless index

          T.must(child_nodes[0...index])
        end

        #: -> Prism::Node?
        def previous_node
          previous_nodes.last
        end

        #: -> Array[Prism::Node]
        def next_nodes
          parent = parent_node
          child_nodes = parent.child_nodes.compact

          index = child_nodes.index(node)
          raise Error, "Node #{@node} not found in nesting node #{parent}" unless index

          T.must(child_nodes.compact[(index + 1)..-1])
        end

        #: -> Prism::Node?
        def next_node
          next_nodes.first
        end

        #: -> NodeContext?
        def sclass_context
          sclass = nil #: Prism::SingletonClassNode?

          nesting = @nesting.dup
          until nesting.empty? || sclass
            node = nesting.pop
            next unless node.is_a?(Prism::SingletonClassNode)

            sclass = node
          end

          return unless sclass.is_a?(Prism::SingletonClassNode)

          body = sclass.body
          return NodeContext.new(@source, @comments, sclass, nesting) unless body.is_a?(Prism::StatementsNode)

          nodes = body.child_nodes.reject do |node|
            sorbet_signature?(node) || sorbet_extend_sig?(node)
          end

          if nodes.size <= 1
            return NodeContext.new(@source, @comments, sclass, nesting)
          end

          nil
        end

        #: (Prism::Node? node) -> bool
        def sorbet_signature?(node)
          node.is_a?(Prism::CallNode) && node.name == :sig
        end

        #: (Prism::Node? node) -> bool
        def sorbet_extend_sig?(node)
          return false unless node.is_a?(Prism::CallNode)
          return false unless node.name == :extend

          args = node.arguments
          return false unless args
          return false unless args.arguments.size == 1

          args.arguments.first&.slice == "T::Sig"
        end

        #: (Integer start_line, Integer end_line) -> Array[Prism::Comment]
        def comments_between_lines(start_line, end_line)
          comments = [] #: Array[Prism::Comment]

          (start_line + 1).upto(end_line - 1) do |line|
            comment = @comments[line]
            comments << comment if comment
          end

          comments
        end

        #: (Prism::Node node) -> Array[Prism::Comment]
        def attached_comments(node)
          comments = [] #: Array[Prism::Comment]

          start_line = node.location.start_line - 1
          start_line.downto(1) do |line|
            comment = @comments[line]
            break unless comment

            comments << comment
          end

          comments.reverse
        end

        #: -> Array[Prism::Node]
        def attached_sigs
          nodes = [] #: Array[Prism::Node]

          previous_nodes.reverse_each do |prev_node|
            break unless sorbet_signature?(prev_node)

            nodes << prev_node
          end

          nodes.reverse
        end

        #: -> Prism::CallNode?
        def attached_sig
          previous_nodes.reverse_each do |node|
            if node.is_a?(Prism::Comment)
              next
            elsif sorbet_signature?(node)
              return T.cast(node, Prism::CallNode)
            else
              break
            end
          end

          nil
        end
      end

      class NodeFinder < Visitor
        class << self
          #: (String source, Location location, Definition::Kind? kind) -> NodeContext
          def find(source, location, kind)
            result = Prism.parse(source)

            unless result.success?
              message = result.errors.map do |e|
                "#{e.message} (at #{e.location.start_line}:#{e.location.start_column})."
              end.join(" ")

              raise ParseError, "Error while parsing #{location.file}: #{message}"
            end

            visitor = new(location, kind)
            visitor.visit(result.value)

            node = visitor.node
            unless node
              raise Error, "Can't find node at #{location}"
            end

            if kind && !node_match_kind?(node, kind)
              raise Error, "Can't find node at #{location}, expected #{kind} but got #{node.class}"
            end

            comments_by_line = result.comments.to_h do |comment|
              [comment.location.start_line, comment]
            end #: Hash[Integer, Prism::Comment]

            NodeContext.new(source, comments_by_line, node, visitor.nodes_nesting)
          end

          #: (Prism::Node node, Definition::Kind kind) -> bool
          def node_match_kind?(node, kind)
            case kind
            when Definition::Kind::AttrReader, Definition::Kind::AttrWriter
              node.is_a?(Prism::SymbolNode)
            when Definition::Kind::Class
              node.is_a?(Prism::ClassNode)
            when Definition::Kind::Constant
              node.is_a?(Prism::ConstantWriteNode) ||
                node.is_a?(Prism::ConstantAndWriteNode) ||
                node.is_a?(Prism::ConstantOrWriteNode) ||
                node.is_a?(Prism::ConstantOperatorWriteNode) ||
                node.is_a?(Prism::ConstantPathWriteNode) ||
                node.is_a?(Prism::ConstantPathAndWriteNode) ||
                node.is_a?(Prism::ConstantPathOrWriteNode) ||
                node.is_a?(Prism::ConstantPathOperatorWriteNode) ||
                node.is_a?(Prism::ConstantTargetNode)
            when Definition::Kind::Method
              node.is_a?(Prism::DefNode)
            when Definition::Kind::Module
              node.is_a?(Prism::ModuleNode)
            end
          end
        end

        #: Prism::Node?
        attr_reader :node

        #: Array[Prism::Node]
        attr_reader :nodes_nesting

        #: (Location location, Definition::Kind? kind) -> void
        def initialize(location, kind)
          super()
          @location = location
          @kind = kind
          @node = nil #: Prism::Node?
          @nodes_nesting = [] #: Array[Prism::Node]
        end

        # @override
        #: (Prism::Node? node) -> void
        def visit(node)
          return unless node

          location = Location.from_prism(@location.file, node.location)

          if location == @location
            # We found the node we're looking for at `@location`
            @node = node

            # The node we found matches the kind we're looking for, we can stop here
            return if @kind && self.class.node_match_kind?(node, @kind)

            # There may be a more precise child inside the node that also matches `@location`, let's visit them
            @nodes_nesting << node
            super(node)
            @nodes_nesting.pop if @nodes_nesting.last == @node
          elsif location.include?(@location)
            # The node we're looking for is inside `node`, let's visit it
            @nodes_nesting << node
            super(node)
          end
        end
      end
    end
  end
end

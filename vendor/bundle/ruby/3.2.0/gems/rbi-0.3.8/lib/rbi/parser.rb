# typed: strict
# frozen_string_literal: true

require "prism"

module RBI
  class ParseError < Error
    #: Loc
    attr_reader :location

    #: (String message, Loc location) -> void
    def initialize(message, location)
      super(message)
      @location = location
    end
  end

  class UnexpectedParserError < Error
    #: Loc
    attr_reader :last_location

    #: (Exception parent_exception, Loc last_location) -> void
    def initialize(parent_exception, last_location)
      super(parent_exception)
      set_backtrace(parent_exception.backtrace)
      @last_location = last_location
    end

    #: (?io: (IO | StringIO)) -> void
    def print_debug(io: $stderr)
      io.puts ""
      io.puts "##################################"
      io.puts "### RBI::Parser internal error ###"
      io.puts "##################################"
      io.puts ""
      io.puts "There was an internal parser error while processing this source."
      io.puts ""
      io.puts "Error: #{message} while parsing #{last_location}:"
      io.puts ""
      io.puts last_location.source || "<no source>"
      io.puts ""
      io.puts "Please open an issue at https://github.com/Shopify/rbi/issues/new."
      io.puts ""
      io.puts "##################################"
      io.puts ""
    end
  end

  class Parser
    class << self
      #: (String string) -> Tree
      def parse_string(string)
        Parser.new.parse_string(string)
      end

      #: (String path) -> Tree
      def parse_file(path)
        Parser.new.parse_file(path)
      end

      #: (Array[String] paths) -> Array[Tree]
      def parse_files(paths)
        parser = Parser.new
        paths.map { |path| parser.parse_file(path) }
      end

      #: (Array[String] strings) -> Array[Tree]
      def parse_strings(strings)
        parser = Parser.new
        strings.map { |string| parser.parse_string(string) }
      end
    end

    #: (String string) -> Tree
    def parse_string(string)
      parse(string, file: "-")
    end

    #: (String path) -> Tree
    def parse_file(path)
      parse(::File.read(path), file: path)
    end

    private

    #: (String source, file: String) -> Tree
    def parse(source, file:)
      result = Prism.parse(source)
      unless result.success?
        message = result.errors.map { |e| "#{e.message}." }.join(" ")
        error = result.errors.first
        location = Loc.new(file: file, begin_line: error.location.start_line, begin_column: error.location.start_column)
        raise ParseError.new(message, location)
      end

      visitor = TreeBuilder.new(source, comments: result.comments, file: file)
      visitor.visit(result.value)
      visitor.tree
    rescue ParseError => e
      raise e
    rescue => e
      last_node = visitor&.last_node
      last_location = if last_node
        Loc.from_prism(file, last_node.location)
      else
        Loc.new(file: file)
      end

      exception = UnexpectedParserError.new(e, last_location)
      exception.print_debug
      raise exception
    end

    class Visitor < Prism::Visitor
      #: (String source, file: String) -> void
      def initialize(source, file:)
        super()

        @source = source
        @file = file
      end

      private

      #: (Prism::Node node) -> Loc
      def node_loc(node)
        Loc.from_prism(@file, node.location)
      end

      #: (Prism::Node? node) -> String?
      def node_string(node)
        return unless node

        node.slice
      end

      #: (Prism::Node node) -> String
      def node_string!(node)
        node_string(node) #: as !nil
      end

      #: (Prism::Node node) -> Prism::Location
      def adjust_prism_location_for_heredoc(node)
        visitor = HeredocLocationVisitor.new(
          node.location.send(:source),
          node.location.start_offset,
          node.location.end_offset,
        )
        visitor.visit(node)
        visitor.location
      end

      #: (Prism::Node? node) -> bool
      def self?(node)
        node.is_a?(Prism::SelfNode)
      end

      #: (Prism::Node? node) -> bool
      def t_sig_without_runtime?(node)
        !!(node.is_a?(Prism::ConstantPathNode) && node_string(node) =~ /(::)?T::Sig::WithoutRuntime/)
      end
    end

    class TreeBuilder < Visitor
      #: Tree
      attr_reader :tree

      #: Prism::Node?
      attr_reader :last_node

      #: (String source, comments: Array[Prism::Comment], file: String) -> void
      def initialize(source, comments:, file:)
        super(source, file: file)

        @comments_by_line = comments.to_h { |c| [c.location.start_line, c] } #: Hash[Integer, Prism::Comment]
        @tree = Tree.new #: Tree

        @scopes_stack = [@tree] #: Array[Tree]
        @last_node = nil #: Prism::Node?
        @last_sigs = [] #: Array[RBI::Sig]
      end

      # @override
      #: (Prism::ClassNode node) -> void
      def visit_class_node(node)
        @last_node = node
        superclass_name = node_string(node.superclass)
        scope = case superclass_name
        when /^(::)?T::Struct$/
          TStruct.new(
            node_string!(node.constant_path),
            loc: node_loc(node),
            comments: node_comments(node),
          )
        when /^(::)?T::Enum$/
          TEnum.new(
            node_string!(node.constant_path),
            loc: node_loc(node),
            comments: node_comments(node),
          )
        else
          Class.new(
            node_string!(node.constant_path),
            superclass_name: superclass_name,
            loc: node_loc(node),
            comments: node_comments(node),
          )
        end

        current_scope << scope
        @scopes_stack << scope
        visit(node.body)
        scope.nodes.concat(current_sigs)
        collect_dangling_comments(node)
        @scopes_stack.pop
        @last_node = nil
      end

      # @override
      #: (Prism::ConstantWriteNode node) -> void
      def visit_constant_write_node(node)
        @last_node = node
        visit_constant_assign(node)
        @last_node = nil
      end

      # @override
      #: (Prism::ConstantPathWriteNode node) -> void
      def visit_constant_path_write_node(node)
        @last_node = node
        visit_constant_assign(node)
        @last_node = nil
      end

      #: ((Prism::ConstantWriteNode | Prism::ConstantPathWriteNode) node) -> void
      def visit_constant_assign(node)
        struct = parse_struct(node)

        current_scope << if struct
          struct
        elsif t_enum_value?(node)
          TEnumValue.new(
            case node
            when Prism::ConstantWriteNode
              node.name.to_s
            when Prism::ConstantPathWriteNode
              node_string!(node.target)
            end,
            loc: node_loc(node),
            comments: node_comments(node),
          )
        else
          adjusted_node_location = adjust_prism_location_for_heredoc(node)

          adjusted_value_location = Prism::Location.new(
            node.value.location.send(:source),
            node.value.location.start_offset,
            adjusted_node_location.end_offset - node.value.location.start_offset,
          )

          if type_variable_definition?(node.value)
            TypeMember.new(
              case node
              when Prism::ConstantWriteNode
                node.name.to_s
              when Prism::ConstantPathWriteNode
                node_string!(node.target)
              end,
              adjusted_value_location.slice,
              loc: Loc.from_prism(@file, adjusted_node_location),
              comments: node_comments(node),
            )
          else
            Const.new(
              case node
              when Prism::ConstantWriteNode
                node.name.to_s
              when Prism::ConstantPathWriteNode
                node_string!(node.target)
              end,
              adjusted_value_location.slice,
              loc: Loc.from_prism(@file, adjusted_node_location),
              comments: node_comments(node),
            )
          end
        end
      end

      # @override
      #: (Prism::DefNode node) -> void
      def visit_def_node(node)
        @last_node = node

        # We need to collect the comments with `current_sigs_comments` _before_ visiting the parameters to make sure
        # the method comments are properly associated with the sigs and not the parameters.
        sigs = current_sigs
        comments = detach_comments_from_sigs(sigs) + node_comments(node)
        params = parse_params(node.parameters)

        current_scope << Method.new(
          node.name.to_s,
          params: params,
          sigs: sigs,
          loc: node_loc(node),
          comments: comments,
          is_singleton: !!node.receiver,
        )
        @last_node = nil
      end

      # @override
      #: (Prism::ModuleNode node) -> void
      def visit_module_node(node)
        @last_node = node
        scope = Module.new(
          node_string!(node.constant_path),
          loc: node_loc(node),
          comments: node_comments(node),
        )

        current_scope << scope
        @scopes_stack << scope
        visit(node.body)
        scope.nodes.concat(current_sigs)
        collect_dangling_comments(node)
        @scopes_stack.pop
        @last_node = nil
      end

      # @override
      #: (Prism::ProgramNode node) -> void
      def visit_program_node(node)
        @last_node = node
        super
        @tree.nodes.concat(current_sigs)
        collect_orphan_comments
        separate_header_comments
        set_root_tree_loc
        @last_node = nil
      end

      # @override
      #: (Prism::SingletonClassNode node) -> void
      def visit_singleton_class_node(node)
        @last_node = node
        scope = SingletonClass.new(
          loc: node_loc(node),
          comments: node_comments(node),
        )

        current_scope << scope
        @scopes_stack << scope
        visit(node.body)
        scope.nodes.concat(current_sigs)
        collect_dangling_comments(node)
        @scopes_stack.pop
        @last_node = nil
      end

      #: (Prism::CallNode node) -> void
      def visit_call_node(node)
        @last_node = node
        message = node.name.to_s
        case message
        when "abstract!", "sealed!", "interface!"
          current_scope << Helper.new(
            message.delete_suffix("!"),
            loc: node_loc(node),
            comments: node_comments(node),
          )
        when "attr_reader"
          args = node.arguments

          unless args.is_a?(Prism::ArgumentsNode) && args.arguments.any?
            @last_node = nil
            return
          end

          sigs = current_sigs
          comments = detach_comments_from_sigs(sigs) + node_comments(node)

          current_scope << AttrReader.new(
            *args.arguments.map { |arg| node_string!(arg).delete_prefix(":").to_sym },
            sigs: sigs,
            loc: node_loc(node),
            comments: comments,
          )
        when "attr_writer"
          args = node.arguments

          unless args.is_a?(Prism::ArgumentsNode) && args.arguments.any?
            @last_node = nil
            return
          end

          sigs = current_sigs
          comments = detach_comments_from_sigs(sigs) + node_comments(node)

          current_scope << AttrWriter.new(
            *args.arguments.map { |arg| node_string!(arg).delete_prefix(":").to_sym },
            sigs: sigs,
            loc: node_loc(node),
            comments: comments,
          )
        when "attr_accessor"
          args = node.arguments

          unless args.is_a?(Prism::ArgumentsNode) && args.arguments.any?
            @last_node = nil
            return
          end

          sigs = current_sigs
          comments = detach_comments_from_sigs(sigs) + node_comments(node)

          current_scope << AttrAccessor.new(
            *args.arguments.map { |arg| node_string!(arg).delete_prefix(":").to_sym },
            sigs: sigs,
            loc: node_loc(node),
            comments: comments,
          )
        when "enums"
          if node.block && node.arguments.nil?
            scope = TEnumBlock.new(loc: node_loc(node), comments: node_comments(node))
            current_scope << scope
            @scopes_stack << scope
            visit(node.block)
            @scopes_stack.pop
          else
            current_scope << Send.new(
              message,
              parse_send_args(node.arguments),
              loc: node_loc(node),
              comments: node_comments(node),
            )
          end
        when "extend"
          args = node.arguments

          unless args.is_a?(Prism::ArgumentsNode) && args.arguments.any?
            @last_node = nil
            return
          end

          current_scope << Extend.new(
            *args.arguments.map { |arg| node_string!(arg) },
            loc: node_loc(node),
            comments: node_comments(node),
          )
        when "include"
          args = node.arguments

          unless args.is_a?(Prism::ArgumentsNode) && args.arguments.any?
            @last_node = nil
            return
          end

          current_scope << Include.new(
            *args.arguments.map { |arg| node_string!(arg) },
            loc: node_loc(node),
            comments: node_comments(node),
          )
        when "mixes_in_class_methods"
          args = node.arguments

          unless args.is_a?(Prism::ArgumentsNode) && args.arguments.any?
            @last_node = nil
            return
          end

          current_scope << MixesInClassMethods.new(
            *args.arguments.map { |arg| node_string!(arg) },
            loc: node_loc(node),
            comments: node_comments(node),
          )
        when "private", "protected", "public"
          args = node.arguments
          if args.is_a?(Prism::ArgumentsNode) && args.arguments.any?
            visit(node.arguments)
            last_node = @scopes_stack.last&.nodes&.last
            case last_node
            when Method, Attr
              last_node.visibility = parse_visibility(node.name.to_s, node)
            when Send
              current_scope << Send.new(
                message,
                parse_send_args(node.arguments),
                loc: node_loc(node),
                comments: node_comments(node),
              )
            end
          else
            current_scope << parse_visibility(node.name.to_s, node)
          end
        when "prop", "const"
          parse_tstruct_field(node)
        when "requires_ancestor"
          block = node.block

          unless block.is_a?(Prism::BlockNode)
            @last_node = nil
            return
          end

          body = block.body

          unless body.is_a?(Prism::StatementsNode)
            @last_node = nil
            return
          end

          current_scope << RequiresAncestor.new(
            node_string!(body),
            loc: node_loc(node),
            comments: node_comments(node),
          )
        when "sig"
          unless node.receiver.nil? || self?(node.receiver) || t_sig_without_runtime?(node.receiver)
            @last_node = nil
            return
          end
          @last_sigs << parse_sig(node)
        else
          current_scope << Send.new(
            message,
            parse_send_args(node.arguments),
            loc: node_loc(node),
            comments: node_comments(node),
          )
        end

        @last_node = nil
      end

      private

      # Collect all the remaining comments within a node
      #: (Prism::Node node) -> void
      def collect_dangling_comments(node)
        first_line = node.location.start_line
        last_line = node.location.end_line

        last_node_last_line = node.child_nodes.last&.location&.end_line

        first_line.upto(last_line) do |line|
          comment = @comments_by_line[line]
          next unless comment
          break if last_node_last_line && line <= last_node_last_line

          current_scope << parse_comment(comment)
          @comments_by_line.delete(line)
        end
      end

      # Collect all the remaining comments after visiting the tree
      #: -> void
      def collect_orphan_comments
        last_line = nil #: Integer?
        last_node_end = @tree.nodes.last&.loc&.end_line

        @comments_by_line.each do |line, comment|
          # Associate the comment either with the header or the file or as a dangling comment at the end
          recv = if last_node_end && line >= last_node_end
            @tree
          else
            @tree.comments
          end

          # Preserve blank lines in comments
          if last_line && line > last_line + 1
            recv << BlankLine.new(loc: Loc.from_prism(@file, comment.location))
          end

          recv << parse_comment(comment)
          last_line = line
        end
      end

      #: -> Tree
      def current_scope
        @scopes_stack.last #: as !nil # Should never be nil since we create a Tree as the root
      end

      #: -> Array[Sig]
      def current_sigs
        sigs = @last_sigs.dup
        @last_sigs.clear
        sigs
      end

      #: (Array[Sig] sigs) -> Array[Comment]
      def detach_comments_from_sigs(sigs)
        comments = [] #: Array[Comment]

        sigs.each do |sig|
          comments += sig.comments.dup
          sig.comments.clear
        end

        comments
      end

      #: (Prism::Node node) -> Array[Comment]
      def node_comments(node)
        comments = []

        start_line = node.location.start_line
        start_line -= 1 unless @comments_by_line.key?(start_line)

        rbs_continuation = [] #: Array[Prism::Comment]

        start_line.downto(1) do |line|
          comment = @comments_by_line[line]
          break unless comment

          text = comment.location.slice

          # If we find a RBS comment continuation `#|`, we store it until we find the start with `#:`
          if text.start_with?("#|")
            rbs_continuation << comment
            @comments_by_line.delete(line)
            next
          end

          loc = Loc.from_prism(@file, comment.location)

          # If we find the start of a RBS comment, we create a new RBSComment
          # Note that we ignore RDoc directives such as `:nodoc:`
          # See https://ruby.github.io/rdoc/RDoc/MarkupReference.html#class-RDoc::MarkupReference-label-Directives
          if text.start_with?("#:") && !(text =~ /^#:[a-z_]+:/)
            text = text.sub(/^#: ?/, "").rstrip

            # If we found continuation comments, we merge them in reverse order (since we go from bottom to top)
            rbs_continuation.reverse_each do |rbs_comment|
              continuation_text = rbs_comment.location.slice.sub(/^#\| ?/, "").strip
              continuation_loc = Loc.from_prism(@file, rbs_comment.location)
              loc = loc.join(continuation_loc)
              text = "#{text}#{continuation_text}"
            end

            rbs_continuation.clear
            comments.unshift(RBSComment.new(text, loc: loc))
          else
            # If we have unused continuation comments, we should inject them back to not lose them
            rbs_continuation.each do |rbs_comment|
              comments.unshift(parse_comment(rbs_comment))
            end

            rbs_continuation.clear
            comments.unshift(parse_comment(comment))
          end

          @comments_by_line.delete(line)
        end

        # If we have unused continuation comments, we should inject them back to not lose them
        rbs_continuation.each do |rbs_comment|
          comments.unshift(parse_comment(rbs_comment))
        end
        rbs_continuation.clear

        comments
      end

      #: (Prism::Comment node) -> Comment
      def parse_comment(node)
        text = node.location.slice.sub(/^# ?/, "").rstrip
        loc = Loc.from_prism(@file, node.location)
        Comment.new(text, loc: loc)
      end

      #: (Prism::Node? node) -> Array[Arg]
      def parse_send_args(node)
        args = [] #: Array[Arg]
        return args unless node.is_a?(Prism::ArgumentsNode)

        node.arguments.each do |arg|
          case arg
          when Prism::KeywordHashNode
            arg.elements.each do |assoc|
              next unless assoc.is_a?(Prism::AssocNode)

              args << KwArg.new(
                node_string!(assoc.key).delete_suffix(":"),
                node_string(assoc.value), #: as !nil
              )
            end
          else
            args << Arg.new(
              node_string(arg), #: as !nil
            )
          end
        end

        args
      end

      #: (Prism::Node? node) -> Array[Param]
      def parse_params(node)
        return [] unless node.is_a?(Prism::ParametersNode)

        node_params = [
          *node.requireds,
          *node.optionals,
          *node.rest,
          *node.posts,
          *node.keywords,
          *node.keyword_rest,
          *node.block,
        ].flatten

        node_params.map do |param|
          case param
          when Prism::RequiredParameterNode
            ReqParam.new(
              param.name.to_s,
              loc: node_loc(param),
              comments: node_comments(param),
            )
          when Prism::OptionalParameterNode
            OptParam.new(
              param.name.to_s,
              node_string!(param.value),
              loc: node_loc(param),
              comments: node_comments(param),
            )
          when Prism::RestParameterNode
            RestParam.new(
              param.name&.to_s || "*args",
              loc: node_loc(param),
              comments: node_comments(param),
            )
          when Prism::RequiredKeywordParameterNode
            KwParam.new(
              param.name.to_s.delete_suffix(":"),
              loc: node_loc(param),
              comments: node_comments(param),
            )
          when Prism::OptionalKeywordParameterNode
            KwOptParam.new(
              param.name.to_s.delete_suffix(":"),
              node_string!(param.value),
              loc: node_loc(param),
              comments: node_comments(param),
            )
          when Prism::KeywordRestParameterNode
            KwRestParam.new(
              param.name&.to_s || "**kwargs",
              loc: node_loc(param),
              comments: node_comments(param),
            )
          when Prism::BlockParameterNode
            BlockParam.new(
              param.name&.to_s || "&block",
              loc: node_loc(param),
              comments: node_comments(param),
            )
          else
            raise ParseError.new("Unexpected parameter node `#{param.class}`", node_loc(param))
          end
        end
      end

      #: (Prism::CallNode node) -> Sig
      def parse_sig(node)
        builder = SigBuilder.new(@source, file: @file)
        builder.current.loc = node_loc(node)
        builder.visit_call_node(node)
        builder.current.comments = node_comments(node)
        builder.current
      end

      #: ((Prism::ConstantWriteNode | Prism::ConstantPathWriteNode) node) -> Struct?
      def parse_struct(node)
        send = node.value
        return unless send.is_a?(Prism::CallNode)
        return unless send.message == "new"

        recv = send.receiver
        return unless recv
        return unless node_string(recv) =~ /(::)?Struct/

        members = []
        keyword_init = false #: bool

        args = send.arguments
        if args.is_a?(Prism::ArgumentsNode)
          args.arguments.each do |arg|
            case arg
            when Prism::SymbolNode
              members << arg.value
            when Prism::KeywordHashNode
              arg.elements.each do |assoc|
                next unless assoc.is_a?(Prism::AssocNode)

                key = node_string!(assoc.key)
                val = node_string(assoc.value)

                keyword_init = val == "true" if key == "keyword_init:"
              end
            end
          end
        end

        name = case node
        when Prism::ConstantWriteNode
          node.name.to_s
        when Prism::ConstantPathWriteNode
          node_string!(node.target)
        end

        loc = node_loc(node)
        comments = node_comments(node)
        struct = Struct.new(name, members: members, keyword_init: keyword_init, loc: loc, comments: comments)
        @scopes_stack << struct
        visit(send.block)
        @scopes_stack.pop
        struct
      end

      #: (Prism::CallNode send) -> void
      def parse_tstruct_field(send)
        args = send.arguments
        return unless args.is_a?(Prism::ArgumentsNode)

        name_arg, type_arg, *rest = args.arguments
        return unless name_arg
        return unless type_arg

        name = node_string!(name_arg).delete_prefix(":")
        type = node_string!(type_arg)
        loc = node_loc(send)
        comments = node_comments(send)
        default_value = nil #: String?

        rest.each do |arg|
          next unless arg.is_a?(Prism::KeywordHashNode)

          arg.elements.each do |assoc|
            next unless assoc.is_a?(Prism::AssocNode)

            if node_string(assoc.key) == "default:"
              default_value = node_string(assoc.value)
            end
          end
        end

        current_scope << case send.message
        when "const"
          TStructConst.new(name, type, default: default_value, loc: loc, comments: comments)
        when "prop"
          TStructProp.new(name, type, default: default_value, loc: loc, comments: comments)
        else
          raise ParseError.new("Unexpected message `#{send.message}`", loc)
        end
      end

      #: (String name, Prism::Node node) -> Visibility
      def parse_visibility(name, node)
        case name
        when "public"
          Public.new(loc: node_loc(node), comments: node_comments(node))
        when "protected"
          Protected.new(loc: node_loc(node), comments: node_comments(node))
        when "private"
          Private.new(loc: node_loc(node), comments: node_comments(node))
        else
          raise ParseError.new("Unexpected visibility `#{name}`", node_loc(node))
        end
      end

      #: -> void
      def separate_header_comments
        current_scope.nodes.dup.each do |child_node|
          break unless child_node.is_a?(Comment) || child_node.is_a?(BlankLine)

          current_scope.comments << child_node
          child_node.detach
        end
      end

      #: -> void
      def set_root_tree_loc
        first_loc = tree.nodes.first&.loc
        last_loc = tree.nodes.last&.loc

        @tree.loc = Loc.new(
          file: @file,
          begin_line: first_loc&.begin_line || 0,
          begin_column: first_loc&.begin_column || 0,
          end_line: last_loc&.end_line || 0,
          end_column: last_loc&.end_column || 0,
        )
      end

      #: (Prism::Node? node) -> bool
      def type_variable_definition?(node)
        node.is_a?(Prism::CallNode) && (node.message == "type_member" || node.message == "type_template")
      end

      #: (Prism::Node? node) -> bool
      def t_enum_value?(node)
        return false unless current_scope.is_a?(TEnumBlock)

        return false unless node.is_a?(Prism::ConstantWriteNode)

        value = node.value
        return false unless value.is_a?(Prism::CallNode)
        return false unless value.message == "new"

        true
      end
    end

    class SigBuilder < Visitor
      #: Sig
      attr_reader :current

      #: (String content, file: String) -> void
      def initialize(content, file:)
        super

        @current = Sig.new #: Sig
      end

      # @override
      #: (Prism::CallNode node) -> void
      def visit_call_node(node)
        case node.message
        when "sig"
          @current.without_runtime = t_sig_without_runtime?(node.receiver)

          args = node.arguments
          if args.is_a?(Prism::ArgumentsNode)
            args.arguments.each do |arg|
              @current.is_final = node_string(arg) == ":final"
            end
          end
        when "abstract"
          @current.is_abstract = true
        when "checked"
          args = node.arguments
          if args.is_a?(Prism::ArgumentsNode)
            arg = node_string(args.arguments.first)
            @current.checked = arg&.delete_prefix(":")&.to_sym
          end
        when "override"
          @current.is_override = true
          @current.allow_incompatible_override = allow_incompatible_override?(node, "true")
          @current.allow_incompatible_override_visibility = allow_incompatible_override?(node, ":visibility")
        when "overridable"
          @current.is_overridable = true
        when "params"
          visit(node.arguments)
        when "returns"
          args = node.arguments
          if args.is_a?(Prism::ArgumentsNode)
            first = args.arguments.first
            @current.return_type = node_string!(first) if first
          end
        when "type_parameters"
          args = node.arguments
          if args.is_a?(Prism::ArgumentsNode)
            args.arguments.each do |arg|
              @current.type_params << node_string!(arg).delete_prefix(":")
            end
          end
        when "void"
          @current.return_type = "void"
        end

        visit(node.receiver)
        visit(node.block)
      end

      # @override
      #: (Prism::AssocNode node) -> void
      def visit_assoc_node(node)
        @current.params << SigParam.new(
          node_string!(node.key).delete_suffix(":"),
          node_string!(node.value),
        )
      end

      #: (Prism::CallNode node, String value) -> bool
      def allow_incompatible_override?(node, value)
        args = node.arguments&.arguments

        keywords_hash = args
          &.grep(Prism::KeywordHashNode)
          &.first

        !!keywords_hash
          &.elements
          &.any? do |assoc|
            assoc.is_a?(Prism::AssocNode) &&
              node_string(assoc.key) == "allow_incompatible:" &&
              node_string(assoc.value) == value
          end
      end
    end

    class HeredocLocationVisitor < Prism::Visitor
      #: (Prism::Source source, Integer begin_offset, Integer end_offset) -> void
      def initialize(source, begin_offset, end_offset)
        super()
        @source = source
        @begin_offset = begin_offset
        @end_offset = end_offset
        @offset_last_newline = false #: bool
      end

      # @override
      #: (Prism::StringNode node) -> void
      def visit_string_node(node)
        return unless node.heredoc?

        closing_loc = node.closing_loc
        return unless closing_loc

        handle_string_node(node)
      end

      # @override
      #: (Prism::InterpolatedStringNode node) -> void
      def visit_interpolated_string_node(node)
        return super unless node.heredoc?

        closing_loc = node.closing_loc
        return super unless closing_loc

        handle_string_node(node)
      end

      #: -> Prism::Location
      def location
        Prism::Location.new(
          @source,
          @begin_offset,
          @end_offset - @begin_offset - (@offset_last_newline ? 1 : 0),
        )
      end

      private

      #: (Prism::StringNode | Prism::InterpolatedStringNode node) -> void
      def handle_string_node(node)
        closing_loc = node.closing_loc #: as !nil

        if closing_loc.end_offset > @end_offset
          @end_offset = closing_loc.end_offset
          @offset_last_newline = true if node.closing_loc&.slice&.end_with?("\n")
        end
      end
    end
  end
end

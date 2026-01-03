# typed: strict
# frozen_string_literal: true

module RBI
  class RBSPrinter < Visitor
    class Error < RBI::Error; end

    #: bool
    attr_accessor :print_locs, :in_visibility_group

    #: Node?
    attr_reader :previous_node

    #: Integer
    attr_reader :current_indent

    #: bool
    attr_accessor :positional_names

    #: Integer?
    attr_reader :max_line_length

    #: (
    #|   ?out: (IO | StringIO),
    #|   ?indent: Integer,
    #|   ?print_locs: bool,
    #|   ?positional_names: bool,
    #|   ?max_line_length: Integer?
    #| ) -> void
    def initialize(out: $stdout, indent: 0, print_locs: false, positional_names: true, max_line_length: nil)
      super()
      @out = out
      @current_indent = indent
      @print_locs = print_locs
      @in_visibility_group = false #: bool
      @previous_node = nil #: Node?
      @positional_names = positional_names #: bool
      @max_line_length = max_line_length #: Integer?
    end

    # Printing

    #: -> void
    def indent
      @current_indent += 2
    end

    #: -> void
    def dedent
      @current_indent -= 2
    end

    # Print a string without indentation nor `\n` at the end.
    #: (String string) -> void
    def print(string)
      @out.print(string)
    end

    # Print a string without indentation but with a `\n` at the end.
    #: (?String? string) -> void
    def printn(string = nil)
      print(string) if string
      print("\n")
    end

    # Print a string with indentation but without a `\n` at the end.
    #: (?String? string) -> void
    def printt(string = nil)
      print(" " * @current_indent)
      print(string) if string
    end

    # Print a string with indentation and `\n` at the end.
    #: (String string) -> void
    def printl(string)
      printt
      printn(string)
    end

    # @override
    #: (Array[Node] nodes) -> void
    def visit_all(nodes)
      previous_node = @previous_node
      @previous_node = nil
      nodes.each do |node|
        visit(node)
        @previous_node = node
      end
      @previous_node = previous_node
    end

    # @override
    #: (File file) -> void
    def visit_file(file)
      unless file.comments.empty?
        visit_all(file.comments)
      end

      unless file.root.empty? && file.root.comments.empty?
        printn unless file.comments.empty?
        visit(file.root)
      end
    end

    # @override
    #: (Comment node) -> void
    def visit_comment(node)
      lines = node.text.lines

      if lines.empty?
        printl("#")
      end

      lines.each do |line|
        text = line.rstrip
        printt("#")
        print(" #{text}") unless text.empty?
        printn
      end
    end

    # @override
    #: (BlankLine node) -> void
    def visit_blank_line(node)
      printn
    end

    # @override
    #: (Tree node) -> void
    def visit_tree(node)
      visit_all(node.comments)
      printn if !node.comments.empty? && !node.empty?
      visit_all(node.nodes)
    end

    # @override
    #: (Module node) -> void
    def visit_module(node)
      visit_scope(node)
    end

    # @override
    #: (Class node) -> void
    def visit_class(node)
      visit_scope(node)
    end

    # @override
    #: (Struct node) -> void
    def visit_struct(node)
      visit_scope(node)
    end

    # @override
    #: (SingletonClass node) -> void
    def visit_singleton_class(node)
      visit_scope(node)
    end

    #: (Scope node) -> void
    def visit_scope(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      visit_scope_header(node)
      visit_scope_body(node)
    end

    #: (Scope node) -> void
    def visit_scope_header(node)
      node.nodes.grep(Helper).each do |helper|
        visit(Comment.new("@#{helper.name}"))
      end

      mixins = node.nodes.grep(MixesInClassMethods)
      if mixins.any?
        visit(Comment.new("@mixes_in_class_methods #{mixins.map(&:names).join(", ")}"))
      end

      ancestors = node.nodes.grep(RequiresAncestor)
      if ancestors.any?
        visit(Comment.new("@requires_ancestor #{ancestors.map(&:name).join(", ")}"))
      end

      case node
      when TStruct
        printt("class #{node.name}")
      when TEnum
        printt("class #{node.name}")
      when Module
        printt("module #{node.name}")
      when Class
        printt("class #{node.name}")
        superclass = node.superclass_name
        print(" < #{superclass}") if superclass
      when Struct
        printt("#{node.name} = ::Struct.new")
        if !node.members.empty? || node.keyword_init
          print("(")
          args = node.members.map { |member| ":#{member}" }
          args << "keyword_init: true" if node.keyword_init
          print(args.join(", "))
          print(")")
        end
      when SingletonClass
        printt("class << self")
      else
        raise Error, "Unhandled node: #{node.class}"
      end

      type_params = node.nodes.grep(TypeMember)
      if type_params.any?
        print("[#{type_params.map(&:name).join(", ")}]")
      end

      if !node.empty? && node.is_a?(Struct)
        print(" do")
      end
      printn
    end

    #: (Scope node) -> void
    def visit_scope_body(node)
      unless node.empty?
        indent
        visit_all(node.nodes)
        dedent
      end
      if !node.is_a?(Struct) || !node.empty?
        printl("end")
      end
    end

    # @override
    #: (Const node) -> void
    def visit_const(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      type = parse_t_let(node.value)
      if type
        type = parse_type(type)
        printl("#{node.name}: #{type.rbs_string}")
      else
        printl("#{node.name}: untyped")
      end
    end

    # @override
    #: (AttrAccessor node) -> void
    def visit_attr_accessor(node)
      visit_attr(node)
    end

    # @override
    #: (AttrReader node) -> void
    def visit_attr_reader(node)
      visit_attr(node)
    end

    # @override
    #: (AttrWriter node) -> void
    def visit_attr_writer(node)
      visit_attr(node)
    end

    #: (Attr node) -> void
    def visit_attr(node)
      print_blank_line_before(node)

      node.names.each do |name|
        visit_all(node.comments)
        print_loc(node)
        printt
        unless in_visibility_group || node.visibility.public? || node.visibility.protected?
          self.print(node.visibility.visibility.to_s)
          print(" ")
        end
        case node
        when AttrAccessor
          print("attr_accessor")
        when AttrReader
          print("attr_reader")
        when AttrWriter
          print("attr_writer")
        end
        print(" #{name}")
        first_sig, *_rest = node.sigs # discard remaining signatures
        if first_sig
          print(": ")
          print_attr_sig(node, first_sig)
        else
          print(": untyped")
        end
        printn
      end
    end

    #: (RBI::Attr node, Sig sig) -> void
    def print_attr_sig(node, sig)
      ret_type = sig.return_type

      type = case node
      when AttrReader, AttrAccessor
        parse_type(ret_type).rbs_string
      else
        # For attr_writer, Sorbet will prioritize the return type over the argument type in case of mismatch
        arg_type = sig.params.first
        if arg_type && (ret_type.is_a?(Type::Void) || ret_type == "void")
          # If we have an argument type and the return type is void, we prioritize the argument type
          parse_type(arg_type.type).rbs_string
        else
          # Otherwise, we prioritize the return type
          parse_type(ret_type).rbs_string
        end
      end

      print(type)
    end

    # @override
    #: (Method node) -> void
    def visit_method(node)
      print_blank_line_before(node)
      visit_all(node.comments)

      if node.sigs.any?(&:without_runtime)
        printl("# @without_runtime")
      end

      if node.sigs.any?(&:is_abstract)
        printl("# @abstract")
      end

      if node.sigs.any?(&:is_override)
        if node.sigs.any?(&:allow_incompatible_override)
          printl("# @override(allow_incompatible: true)")
        elsif node.sigs.any?(&:allow_incompatible_override_visibility)
          printl("# @override(allow_incompatible: :visibility)")
        else
          printl("# @override")
        end
      end

      if node.sigs.any?(&:is_overridable)
        printl("# @overridable")
      end

      if node.sigs.any?(&:is_final)
        printl("# @final")
      end

      print_loc(node)
      printt
      unless in_visibility_group || node.visibility.public?
        self.print(node.visibility.visibility.to_s)
        print(" ")
      end
      print("def ")
      print("self.") if node.is_singleton
      print(node.name)
      sigs = node.sigs
      print(": ")
      if sigs.any?
        first, *rest = sigs
        print_method_sig(
          node,
          first, #: as !nil
        )
        if rest.any?
          spaces = node.name.size + 4
          rest.each do |sig|
            printn
            printt
            print("#{" " * spaces}| ")
            print_method_sig(node, sig)
          end
        end
      else
        if node.params.any?
          params = node.params.reject { |param| param.is_a?(BlockParam) }
          block = node.params.find { |param| param.is_a?(BlockParam) }

          print("(")
          params.each_with_index do |param, index|
            print(", ") if index > 0
            visit(param)
          end
          print(") ")
          visit(block)
        end
        print("-> untyped")
      end
      printn
    end

    #: (RBI::Method node, Sig sig) -> void
    def print_method_sig(node, sig)
      old_out = @out
      new_out = StringIO.new

      @out = new_out
      print_method_sig_inline(node, sig)
      @out = old_out

      max_line_length = @max_line_length
      if max_line_length.nil? || new_out.string.size <= max_line_length
        print(new_out.string)
      else
        print_method_sig_multiline(node, sig)
      end
    end

    #: (RBI::Method node, Sig sig) -> void
    def print_method_sig_inline(node, sig)
      unless sig.type_params.empty?
        print("[#{sig.type_params.join(", ")}] ")
      end

      block_param = node.params.find { |param| param.is_a?(BlockParam) }
      sig_block_param = sig.params.find { |param| param.name == block_param&.name }

      sig_params = sig.params.dup
      if block_param
        sig_params.reject! do |param|
          param.name == block_param.name
        end
      end

      unless sig_params.empty?
        print("(")
        sig_params.each_with_index do |param, index|
          print(", ") if index > 0
          print_sig_param(node, param)
        end
        print(") ")
      end
      if sig_block_param
        block_type = sig_block_param.type
        block_type = Type.parse_string(block_type) if block_type.is_a?(String)

        block_is_nilable = false
        if block_type.is_a?(Type::Nilable)
          block_is_nilable = true
          block_type = block_type.type
        end

        type_string = parse_type(block_type).rbs_string.delete_prefix("^")

        skip = false
        case block_type
        when Type::Untyped
          type_string = "(?) -> untyped"
          block_is_nilable = true
        when Type::Simple
          type_string = "(?) -> untyped"
          skip = true if block_type.name == "NilClass"
        end

        if skip
          # no-op, we skip the block definition
        elsif block_is_nilable
          print("?{ #{type_string} } ")
        else
          print("{ #{type_string} } ")
        end
      end

      type = parse_type(sig.return_type)
      print("-> #{type.rbs_string}")

      loc = sig.loc
      print(" # #{loc}") if loc && print_locs
    end

    #: (RBI::Method node, Sig sig) -> void
    def print_method_sig_multiline(node, sig)
      unless sig.type_params.empty?
        print("[#{sig.type_params.join(", ")}] ")
      end

      block_param = node.params.find { |param| param.is_a?(BlockParam) }
      sig_block_param = sig.params.find { |param| param.name == block_param&.name }

      sig_params = sig.params.dup
      if block_param
        sig_params.reject! do |param|
          param.name == block_param.name
        end
      end

      unless sig_params.empty?
        printl("(")
        indent
        sig_params.each_with_index do |param, index|
          printt
          print_sig_param(node, param)
          print(",") if index < sig_params.size - 1
          printn
        end
        dedent
        printt(") ")
      end
      if sig_block_param
        block_type = sig_block_param.type
        block_type = Type.parse_string(block_type) if block_type.is_a?(String)

        block_is_nilable = false
        if block_type.is_a?(Type::Nilable)
          block_is_nilable = true
          block_type = block_type.type
        end

        type_string = parse_type(block_type).rbs_string.delete_prefix("^")

        skip = false
        case block_type
        when Type::Untyped
          type_string = "(?) -> untyped"
          block_is_nilable = true
        when Type::Simple
          type_string = "(?) -> untyped"
          skip = true if block_type.name == "NilClass"
        end

        if skip
          # no-op, we skip the block definition
        elsif block_is_nilable
          print("?{ #{type_string} } ")
        else
          print("{ #{type_string} } ")
        end
      end

      type = parse_type(sig.return_type)
      print("-> #{type.rbs_string}")

      loc = sig.loc
      print(" # #{loc}") if loc && print_locs
    end

    #: (Sig node) -> void
    def visit_sig(node)
      if node.params
        print("(")
        node.params.each do |param|
          visit(param)
        end
        print(") ")
      end

      print("-> #{parse_type(node.return_type).rbs_string}")
    end

    #: (SigParam node) -> void
    def visit_sig_param(node)
      print(parse_type(node.type).rbs_string)
    end

    # @override
    #: (ReqParam node) -> void
    def visit_req_param(node)
      if @positional_names
        print("untyped #{node.name}")
      else
        print("untyped")
      end
    end

    # @override
    #: (OptParam node) -> void
    def visit_opt_param(node)
      if @positional_names
        print("?untyped #{node.name}")
      else
        print("?untyped")
      end
    end

    # @override
    #: (RestParam node) -> void
    def visit_rest_param(node)
      if @positional_names
        print("*untyped #{node.name}")
      else
        print("*untyped")
      end
    end

    # @override
    #: (KwParam node) -> void
    def visit_kw_param(node)
      print("#{node.name}: untyped")
    end

    # @override
    #: (KwOptParam node) -> void
    def visit_kw_opt_param(node)
      print("?#{node.name}: untyped")
    end

    # @override
    #: (KwRestParam node) -> void
    def visit_kw_rest_param(node)
      print("**#{node.name}: untyped")
    end

    # @override
    #: (BlockParam node) -> void
    def visit_block_param(node)
      print("{ (*untyped) -> untyped } ")
    end

    # @override
    #: (Include node) -> void
    def visit_include(node)
      visit_mixin(node)
    end

    # @override
    #: (Extend node) -> void
    def visit_extend(node)
      visit_mixin(node)
    end

    #: (Mixin node) -> void
    def visit_mixin(node)
      return if node.is_a?(MixesInClassMethods) # no-op, `mixes_in_class_methods` is not supported in RBS

      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      case node
      when Include
        printt("include")
      when Extend
        printt("extend")
      end
      printn(" #{node.names.join(", ")}")
    end

    # @override
    #: (Public node) -> void
    def visit_public(node)
      visit_visibility(node)
    end

    # @override
    #: (Protected node) -> void
    def visit_protected(node)
      # no-op, `protected` is not supported in RBS
    end

    # @override
    #: (Private node) -> void
    def visit_private(node)
      visit_visibility(node)
    end

    #: (Visibility node) -> void
    def visit_visibility(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      printl(node.visibility.to_s)
    end

    # @override
    #: (Send node) -> void
    def visit_send(node)
      # no-op, arbitrary sends are not supported in RBS
    end

    # @override
    #: (Arg node) -> void
    def visit_arg(node)
      # no-op
    end

    # @override
    #: (KwArg node) -> void
    def visit_kw_arg(node)
      # no-op
    end

    # @override
    #: (TStruct node) -> void
    def visit_tstruct(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      visit_scope_header(node)
      nodes = node.nodes.dup

      sig = Sig.new
      init = Method.new("initialize", sigs: [sig])
      last_field = -1
      nodes.each_with_index do |child, i|
        case child
        when TStructField
          default = child.default
          init << if default
            KwOptParam.new(child.name, default)
          else
            KwParam.new(child.name)
          end
          sig << SigParam.new(child.name, child.type)
          last_field = i
        end
      end
      nodes.insert(last_field + 1, init)

      indent
      visit_all(nodes)
      dedent

      printl("end")
    end

    # @override
    #: (TStructConst node) -> void
    def visit_tstruct_const(node)
      # `T::Struct.const` is not supported in RBS instead we generate an attribute reader
      accessor = AttrReader.new(node.name.to_sym, comments: node.comments, sigs: [Sig.new(return_type: node.type)])
      visit_attr_reader(accessor)
    end

    # @override
    #: (TStructProp node) -> void
    def visit_tstruct_prop(node)
      # `T::Struct.prop` is not supported in RBS instead we generate an attribute accessor
      accessor = AttrAccessor.new(node.name.to_sym, comments: node.comments, sigs: [Sig.new(return_type: node.type)])
      visit_attr_accessor(accessor)
    end

    # @override
    #: (TEnum node) -> void
    def visit_tenum(node)
      visit_scope(node)
    end

    # @override
    #: (TEnumBlock node) -> void
    def visit_tenum_block(node)
      visit_all(node.nodes)
    end

    # @override
    #: (TEnumValue node) -> void
    def visit_tenum_value(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      t_enum = node.parent_scope&.parent_scope

      if t_enum.is_a?(TEnum)
        printl("#{node.name}: #{t_enum.name}")
      else
        printl("#{node.name}: untyped")
      end
    end

    # @override
    #: (TypeMember node) -> void
    def visit_type_member(node)
      # no-op, we already show them in the scope header
    end

    # @override
    #: (Helper node) -> void
    def visit_helper(node)
      # no-op, we already show them in the scope header
    end

    # @override
    #: (MixesInClassMethods node) -> void
    def visit_mixes_in_class_methods(node)
      visit_mixin(node)
    end

    # @override
    #: (Group node) -> void
    def visit_group(node)
      printn unless previous_node.nil?
      visit_all(node.nodes)
    end

    # @override
    #: (VisibilityGroup node) -> void
    def visit_visibility_group(node)
      self.in_visibility_group = true
      if node.visibility.public?
        printn unless previous_node.nil?
      else
        visit(node.visibility)
        printn
      end
      visit_all(node.nodes)
      self.in_visibility_group = false
    end

    # @override
    #: (RequiresAncestor node) -> void
    def visit_requires_ancestor(node)
      # no-op, we already show them in the scope header
    end

    # @override
    #: (ConflictTree node) -> void
    def visit_conflict_tree(node)
      printl("<<<<<<< #{node.left_name}")
      visit(node.left)
      printl("=======")
      visit(node.right)
      printl(">>>>>>> #{node.right_name}")
    end

    # @override
    #: (ScopeConflict node) -> void
    def visit_scope_conflict(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      printl("<<<<<<< #{node.left_name}")
      visit_scope_header(node.left)
      printl("=======")
      visit_scope_header(node.right)
      printl(">>>>>>> #{node.right_name}")
      visit_scope_body(node.left)
    end

    private

    #: (Node node) -> void
    def print_blank_line_before(node)
      previous_node = self.previous_node
      return unless previous_node
      return if previous_node.is_a?(BlankLine)
      return if previous_node.is_a?(TypeMember) # since we skip them
      return if previous_node.is_a?(Helper) # since we skip them
      return if previous_node.is_a?(Protected) # since we skip them
      return if previous_node.is_a?(RequiresAncestor) # since we skip them
      return if previous_node.is_a?(Send) # since we skip them
      return if previous_node.is_a?(Arg) # since we skip them
      return if previous_node.is_a?(KwArg) # since we skip them
      return if previous_node.is_a?(TEnumBlock) # since we skip them
      return if previous_node.is_a?(MixesInClassMethods) # since we skip them
      return if oneline?(previous_node) && oneline?(node)

      printn
    end

    #: (Node node) -> void
    def print_loc(node)
      loc = node.loc
      printl("# #{loc}") if loc && print_locs
    end

    #: (Method node, SigParam param) -> void
    def print_sig_param(node, param)
      type = parse_type(param.type).rbs_string

      orig_param = node.params.find { |p| p.name == param.name }

      case orig_param
      when ReqParam
        if @positional_names
          print("#{type} #{param.name}")
        else
          print(type)
        end
      when OptParam
        if @positional_names
          print("?#{type} #{param.name}")
        else
          print("?#{type}")
        end
      when RestParam
        if @positional_names
          print("*#{type} #{param.name}")
        else
          print("*#{type}")
        end
      when KwParam
        print("#{param.name}: #{type}")
      when KwOptParam
        print("?#{param.name}: #{type}")
      when KwRestParam
        print("**#{type} #{param.name}")
      else
        raise Error, "Unexpected param type: #{orig_param.class} for param #{param.name}"
      end
    end

    #: (Param node, last: bool) -> void
    def print_param_comment_leading_space(node, last:)
      printn
      printt
      print(" " * (node.name.size + 1))
      print(" ") unless last
      case node
      when OptParam
        print(" " * (node.value.size + 3))
      when RestParam, KwParam, BlockParam
        print(" ")
      when KwRestParam
        print("  ")
      when KwOptParam
        print(" " * (node.value.size + 2))
      end
    end

    #: (SigParam node, last: bool) -> void
    def print_sig_param_comment_leading_space(node, last:)
      printn
      printt
      print(" " * (node.name.size + node.type.to_s.size + 3))
      print(" ") unless last
    end

    #: (Node node) -> bool
    def oneline?(node)
      case node
      when ScopeConflict
        oneline?(node.left)
      when Tree
        false
      when Attr
        node.comments.empty?
      when Method
        node.comments.empty? && node.sigs.empty? && node.params.all? { |p| p.comments.empty? }
      when Sig
        node.params.all? { |p| p.comments.empty? }
      when NodeWithComments
        node.comments.empty?
      when VisibilityGroup
        false
      else
        true
      end
    end

    #: ((Type | String) type) -> Type
    def parse_type(type)
      return type if type.is_a?(Type)

      Type.parse_string(type).simplify
    rescue Type::Error => e
      raise Error, "Failed to parse type `#{type}` (#{e.message})"
    end

    # Parse a string containing a `T.let(x, X)` and extract the type
    #
    # Returns `nil` is the string is not a `T.let`.
    #: (String? code) -> String?
    def parse_t_let(code)
      return unless code

      res = Prism.parse(code)
      return unless res.success?

      node = res.value
      return unless node.is_a?(Prism::ProgramNode)

      node = node.statements.body.first
      return unless node.is_a?(Prism::CallNode)
      return unless node.name == :let
      return unless node.receiver&.slice =~ /^(::)?T$/

      arguments = node.arguments&.arguments
      return unless arguments

      arguments.fetch(1, nil)&.slice
    end
  end

  class TypePrinter
    #: String
    attr_reader :string

    #: (?max_line_length: Integer?) -> void
    def initialize(max_line_length: nil)
      @string = String.new #: String
      @max_line_length = max_line_length
    end

    #: (Type node) -> void
    def visit(node)
      case node
      when Type::Simple
        visit_simple(node)
      when Type::Boolean
        visit_boolean(node)
      when Type::Generic
        visit_generic(node)
      when Type::Anything
        visit_anything(node)
      when Type::Void
        visit_void(node)
      when Type::NoReturn
        visit_no_return(node)
      when Type::Untyped
        visit_untyped(node)
      when Type::SelfType
        visit_self_type(node)
      when Type::AttachedClass
        visit_attached_class(node)
      when Type::Nilable
        visit_nilable(node)
      when Type::ClassOf
        visit_class_of(node)
      when Type::All
        visit_all(node)
      when Type::Any
        visit_any(node)
      when Type::Tuple
        visit_tuple(node)
      when Type::Shape
        visit_shape(node)
      when Type::Proc
        visit_proc(node)
      when Type::TypeParameter
        visit_type_parameter(node)
      when Type::Class
        visit_class(node)
      when Type::Module
        visit_module(node)
      else
        raise Error, "Unhandled node: #{node.class}"
      end
    end

    #: (Type::Simple type) -> void
    def visit_simple(type)
      @string << translate_t_type(type.name.gsub(/\s/, ""))
    end

    #: (Type::Boolean type) -> void
    def visit_boolean(type)
      @string << "bool"
    end

    #: (Type::Generic type) -> void
    def visit_generic(type)
      @string << translate_t_type(type.name.gsub(/\s/, ""))
      @string << "["
      type.params.each_with_index do |arg, index|
        visit(arg)
        @string << ", " if index < type.params.size - 1
      end
      @string << "]"
    end

    #: (Type::Anything type) -> void
    def visit_anything(type)
      @string << "top"
    end

    #: (Type::Void type) -> void
    def visit_void(type)
      @string << "void"
    end

    #: (Type::NoReturn type) -> void
    def visit_no_return(type)
      @string << "bot"
    end

    #: (Type::Untyped type) -> void
    def visit_untyped(type)
      @string << "untyped"
    end

    #: (Type::SelfType type) -> void
    def visit_self_type(type)
      @string << "self"
    end

    #: (Type::AttachedClass type) -> void
    def visit_attached_class(type)
      @string << "instance"
    end

    #: (Type::Nilable type) -> void
    def visit_nilable(type)
      inner = type.type
      if inner.is_a?(Type::Proc)
        @string << "("
      end
      visit(inner)
      if inner.is_a?(Type::Proc)
        @string << ")"
      end
      @string << "?"
    end

    #: (Type::ClassOf type) -> void
    def visit_class_of(type)
      @string << "singleton("
      visit(type.type)
      @string << ")"
    end

    #: (Type::All type) -> void
    def visit_all(type)
      @string << "("
      type.types.each_with_index do |arg, index|
        visit(arg)
        @string << " & " if index < type.types.size - 1
      end
      @string << ")"
    end

    #: (Type::Any type) -> void
    def visit_any(type)
      @string << "("
      type.types.each_with_index do |arg, index|
        visit(arg)
        @string << " | " if index < type.types.size - 1
      end
      @string << ")"
    end

    #: (Type::Tuple type) -> void
    def visit_tuple(type)
      @string << "["
      type.types.each_with_index do |arg, index|
        visit(arg)
        @string << ", " if index < type.types.size - 1
      end
      @string << "]"
    end

    #: (Type::Shape type) -> void
    def visit_shape(type)
      @string << "{"
      type.types.each_with_index do |(key, value), index|
        @string << case key
        when String
          "\"#{key}\" => "
        when Symbol
          if key.match?(/\A[a-zA-Z_]+[a-zA-Z0-9_]*\z/)
            "#{key}: "
          else
            "\"#{key}\": "
          end
        end
        visit(value)
        @string << ", " if index < type.types.size - 1
      end
      @string << "}"
    end

    #: (Type::Proc type) -> void
    def visit_proc(type)
      @string << "^"
      if type.proc_params.any?
        @string << "("
        type.proc_params.each_with_index do |(key, value), index|
          visit(value)
          @string << " #{key}"
          @string << ", " if index < type.proc_params.size - 1
        end
        @string << ") "
      end
      proc_bind = type.proc_bind
      if proc_bind
        @string << "[self: "
        visit(proc_bind)
        @string << "] "
      end
      @string << "-> "
      visit(type.proc_returns)
    end

    #: (Type::TypeParameter type) -> void
    def visit_type_parameter(type)
      @string << type.name.to_s
    end

    #: (Type::Class type) -> void
    def visit_class(type)
      @string << "Class["
      visit(type.type)
      @string << "]"
    end

    #: (Type::Module type) -> void
    def visit_module(type)
      @string << "Module["
      visit(type.type)
      @string << "]"
    end

    private

    #: (String type_name) -> String
    def translate_t_type(type_name)
      case type_name
      when "T::Array"
        "Array"
      when "T::Enumerable"
        "Enumerable"
      when "T::Enumerator"
        "Enumerator"
      when "T::Enumerator::Chain"
        "Enumerator::Chain"
      when "T::Enumerator::Lazy"
        "Enumerator::Lazy"
      when "T::Hash"
        "Hash"
      when "T::Set"
        "Set"
      when "T::Range"
        "Range"
      else
        type_name
      end
    end
  end

  class File
    #: (?out: (IO | StringIO), ?indent: Integer, ?print_locs: bool) -> void
    def rbs_print(out: $stdout, indent: 0, print_locs: false)
      p = RBSPrinter.new(out: out, indent: indent, print_locs: print_locs)
      p.visit_file(self)
    end

    #: (?indent: Integer, ?print_locs: bool) -> String
    def rbs_string(indent: 0, print_locs: false)
      out = StringIO.new
      rbs_print(out: out, indent: indent, print_locs: print_locs)
      out.string
    end
  end

  class Node
    #: (?out: (IO | StringIO), ?indent: Integer, ?print_locs: bool, ?positional_names: bool) -> void
    def rbs_print(out: $stdout, indent: 0, print_locs: false, positional_names: true)
      p = RBSPrinter.new(out: out, indent: indent, print_locs: print_locs, positional_names: positional_names)
      p.visit(self)
    end

    #: (?indent: Integer, ?print_locs: bool, ?positional_names: bool) -> String
    def rbs_string(indent: 0, print_locs: false, positional_names: true)
      out = StringIO.new
      rbs_print(out: out, indent: indent, print_locs: print_locs, positional_names: positional_names)
      out.string
    end
  end

  class Type
    #: -> String
    def rbs_string
      p = TypePrinter.new
      p.visit(self)
      p.string
    end
  end
end

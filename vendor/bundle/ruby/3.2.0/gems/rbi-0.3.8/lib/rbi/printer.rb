# typed: strict
# frozen_string_literal: true

module RBI
  class PrinterError < Error; end

  class Printer < Visitor
    #: bool
    attr_accessor :print_locs, :in_visibility_group

    #: Node?
    attr_reader :previous_node

    #: Integer
    attr_reader :current_indent

    #: Integer?
    attr_reader :max_line_length

    #: (?out: (IO | StringIO), ?indent: Integer, ?print_locs: bool, ?max_line_length: Integer?) -> void
    def initialize(out: $stdout, indent: 0, print_locs: false, max_line_length: nil)
      super()
      @out = out
      @current_indent = indent
      @print_locs = print_locs
      @in_visibility_group = false #: bool
      @previous_node = nil #: Node?
      @max_line_length = max_line_length
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
      strictness = file.strictness
      if strictness
        printl("# typed: #{strictness}")
      end
      unless file.comments.empty?
        printn if strictness
        visit_all(file.comments)
      end

      unless file.root.empty? && file.root.comments.empty?
        printn if strictness || !file.comments.empty?
        visit(file.root)
      end
    end

    private

    # @override
    #: (RBSComment node) -> void
    def visit_rbs_comment(node)
      lines = node.text.lines

      if lines.empty?
        printl("#:")
      end

      lines.each do |line|
        text = line.rstrip
        printt("#:")
        print(" #{text}") unless text.empty?
        printn
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
      case node
      when Module
        printt("module #{node.name}")
      when TEnum
        printt("class #{node.name} < T::Enum")
      when TStruct
        printt("class #{node.name} < T::Struct")
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
        raise PrinterError, "Unhandled node: #{node.class}"
      end
      if node.empty? && !node.is_a?(Struct)
        print("; end")
      elsif !node.empty? && node.is_a?(Struct)
        print(" do")
      end
      printn
    end

    #: (Scope node) -> void
    def visit_scope_body(node)
      return if node.empty?

      indent
      visit_all(node.nodes)
      dedent
      printl("end")
    end

    # @override
    #: (Const node) -> void
    def visit_const(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      printl("#{node.name} = #{node.value}")
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

      visit_all(node.comments)
      node.sigs.each { |sig| visit(sig) }

      print_loc(node)
      printt
      unless in_visibility_group || node.visibility.public?
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
      unless node.names.empty?
        print(" ")
        print(node.names.map { |name| ":#{name}" }.join(", "))
      end
      printn
    end

    # @override
    #: (Method node) -> void
    def visit_method(node)
      print_blank_line_before(node)
      visit_all(node.comments)
      visit_all(node.sigs)

      print_loc(node)
      printt
      unless in_visibility_group || node.visibility.public?
        self.print(node.visibility.visibility.to_s)
        print(" ")
      end
      print("def ")
      print("self.") if node.is_singleton
      print(node.name)
      unless node.params.empty?
        print("(")
        if node.params.all? { |p| p.comments.empty? }
          node.params.each_with_index do |param, index|
            print(", ") if index > 0
            visit(param)
          end
        else
          printn
          indent
          node.params.each_with_index do |param, pindex|
            printt
            visit(param)
            print(",") if pindex < node.params.size - 1

            comment_lines = param.comments.flat_map { |comment| comment.text.lines.map(&:rstrip) }
            comment_lines.each_with_index do |comment, cindex|
              if cindex > 0
                print_param_comment_leading_space(param, last: pindex == node.params.size - 1)
              else
                print(" ")
              end
              print("# #{comment}")
            end
            printn
          end
          dedent
        end
        print(")")
      end
      print("; end")
      printn
    end

    # @override
    #: (ReqParam node) -> void
    def visit_req_param(node)
      print(node.name)
    end

    # @override
    #: (OptParam node) -> void
    def visit_opt_param(node)
      print("#{node.name} = #{node.value}")
    end

    # @override
    #: (RestParam node) -> void
    def visit_rest_param(node)
      print("*#{node.name}")
    end

    # @override
    #: (KwParam node) -> void
    def visit_kw_param(node)
      print("#{node.name}:")
    end

    # @override
    #: (KwOptParam node) -> void
    def visit_kw_opt_param(node)
      print("#{node.name}: #{node.value}")
    end

    # @override
    #: (KwRestParam node) -> void
    def visit_kw_rest_param(node)
      print("**#{node.name}")
    end

    # @override
    #: (BlockParam node) -> void
    def visit_block_param(node)
      print("&#{node.name}")
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
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      case node
      when Include
        printt("include")
      when Extend
        printt("extend")
      when MixesInClassMethods
        printt("mixes_in_class_methods")
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
      visit_visibility(node)
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
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      printt(node.method)
      unless node.args.empty?
        print(" ")
        node.args.each_with_index do |arg, index|
          visit(arg)
          print(", ") if index < node.args.size - 1
        end
      end
      printn
    end

    # @override
    #: (Arg node) -> void
    def visit_arg(node)
      print(node.value)
    end

    # @override
    #: (KwArg node) -> void
    def visit_kw_arg(node)
      print("#{node.keyword}: #{node.value}")
    end

    # @override
    #: (Sig node) -> void
    def visit_sig(node)
      print_loc(node)
      visit_all(node.comments)

      max_line_length = self.max_line_length
      if oneline?(node) && max_line_length.nil?
        print_sig_as_line(node)
      elsif max_line_length
        line = node.string(indent: current_indent)
        if line.length <= max_line_length
          print(line)
        else
          print_sig_as_block(node)
        end
      else
        print_sig_as_block(node)
      end
    end

    # @override
    #: (SigParam node) -> void
    def visit_sig_param(node)
      print("#{node.name}: #{node.type}")
    end

    # @override
    #: (TStruct node) -> void
    def visit_tstruct(node)
      visit_scope(node)
    end

    # @override
    #: (TStructConst node) -> void
    def visit_tstruct_const(node)
      visit_t_struct_field(node)
    end

    # @override
    #: (TStructProp node) -> void
    def visit_tstruct_prop(node)
      visit_t_struct_field(node)
    end

    #: (TStructField node) -> void
    def visit_t_struct_field(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      case node
      when TStructProp
        printt("prop")
      when TStructConst
        printt("const")
      end
      print(" :#{node.name}, #{node.type}")
      default = node.default
      print(", default: #{default}") if default
      printn
    end

    # @override
    #: (TEnum node) -> void
    def visit_tenum(node)
      visit_scope(node)
    end

    # @override
    #: (TEnumBlock node) -> void
    def visit_tenum_block(node)
      print_loc(node)
      visit_all(node.comments)

      printl("enums do")
      indent
      visit_all(node.nodes)
      dedent
      printl("end")
    end

    # @override
    #: (TEnumValue node) -> void
    def visit_tenum_value(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      printl("#{node.name} = new")
    end

    # @override
    #: (TypeMember node) -> void
    def visit_type_member(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      printl("#{node.name} = #{node.value}")
    end

    # @override
    #: (Helper node) -> void
    def visit_helper(node)
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      printl("#{node.name}!")
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
      print_blank_line_before(node)
      print_loc(node)
      visit_all(node.comments)

      printl("requires_ancestor { #{node.name} }")
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

    #: (Node node) -> void
    def print_blank_line_before(node)
      previous_node = self.previous_node
      return unless previous_node
      return if previous_node.is_a?(BlankLine)
      return if oneline?(previous_node) && oneline?(node)

      printn
    end

    #: (Node node) -> void
    def print_loc(node)
      loc = node.loc
      printl("# #{loc}") if loc && print_locs
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
        node.comments.empty? && node.empty?
      when Attr
        node.comments.empty? && node.sigs.empty?
      when Const
        return false unless node.comments.empty?

        loc = node.loc
        return true unless loc

        loc.begin_line == loc.end_line
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

    #: (Sig node) -> void
    def print_sig_as_line(node)
      printt
      print("T::Sig::WithoutRuntime.") if node.without_runtime
      print("sig")
      print("(:final)") if node.is_final
      print(" { ")
      sig_modifiers(node).each do |modifier|
        print("#{modifier}.")
      end
      unless node.params.empty?
        print("params(")
        node.params.each_with_index do |param, index|
          print(", ") if index > 0
          visit(param)
        end
        print(").")
      end
      return_type = node.return_type
      if node.return_type.to_s == "void"
        print("void")
      else
        print("returns(#{return_type})")
      end
      printn(" }")
    end

    #: (Sig node) -> void
    def print_sig_as_block(node)
      modifiers = sig_modifiers(node)

      printt
      print("T::Sig::WithoutRuntime.") if node.without_runtime
      print("sig")
      print("(:final)") if node.is_final
      printn(" do")
      indent
      if modifiers.any?
        printl(
          modifiers.first, #: as !nil
        )
        indent
        modifiers[1..]&.each do |modifier|
          printl(".#{modifier}")
        end
      end

      params = node.params
      if params.any?
        printt
        print(".") if modifiers.any?
        printn("params(")
        indent
        params.each_with_index do |param, pindex|
          printt
          visit(param)
          print(",") if pindex < params.size - 1

          comment_lines = param.comments.flat_map { |comment| comment.text.lines.map(&:rstrip) }
          comment_lines.each_with_index do |comment, cindex|
            if cindex == 0
              print(" ")
            else
              print_sig_param_comment_leading_space(param, last: pindex == params.size - 1)
            end
            print("# #{comment}")
          end
          printn
        end
        dedent
        printt(")")
      end
      printt if params.empty?
      print(".") if modifiers.any? || params.any?

      return_type = node.return_type
      if return_type.to_s == "void"
        print("void")
      else
        print("returns(#{return_type})")
      end
      printn
      dedent
      dedent if modifiers.any?
      printl("end")
    end

    #: (Sig node) -> Array[String]
    def sig_modifiers(node)
      modifiers = [] #: Array[String]
      modifiers << "abstract" if node.is_abstract

      if node.is_override
        modifiers << if node.allow_incompatible_override
          "override(allow_incompatible: true)"
        elsif node.allow_incompatible_override_visibility
          "override(allow_incompatible: :visibility)"
        else
          "override"
        end
      end

      modifiers << "overridable" if node.is_overridable
      modifiers << "type_parameters(#{node.type_params.map { |type| ":#{type}" }.join(", ")})" if node.type_params.any?
      modifiers << "checked(:#{node.checked})" if node.checked
      modifiers
    end
  end

  class File
    #: (?out: (IO | StringIO), ?indent: Integer, ?print_locs: bool, ?max_line_length: Integer?) -> void
    def print(out: $stdout, indent: 0, print_locs: false, max_line_length: nil)
      p = Printer.new(out: out, indent: indent, print_locs: print_locs, max_line_length: max_line_length)
      p.visit_file(self)
    end

    #: (?indent: Integer, ?print_locs: bool, ?max_line_length: Integer?) -> String
    def string(indent: 0, print_locs: false, max_line_length: nil)
      out = StringIO.new
      print(out: out, indent: indent, print_locs: print_locs, max_line_length: max_line_length)
      out.string
    end
  end

  class Node
    #: (?out: (IO | StringIO), ?indent: Integer, ?print_locs: bool, ?max_line_length: Integer?) -> void
    def print(out: $stdout, indent: 0, print_locs: false, max_line_length: nil)
      p = Printer.new(out: out, indent: indent, print_locs: print_locs, max_line_length: max_line_length)
      p.visit(self)
    end

    #: (?indent: Integer, ?print_locs: bool, ?max_line_length: Integer?) -> String
    def string(indent: 0, print_locs: false, max_line_length: nil)
      out = StringIO.new
      print(out: out, indent: indent, print_locs: print_locs, max_line_length: max_line_length)
      out.string
    end
  end
end

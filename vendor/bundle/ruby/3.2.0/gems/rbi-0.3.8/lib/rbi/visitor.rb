# typed: strict
# frozen_string_literal: true

module RBI
  class VisitorError < Error; end

  # @abstract
  class Visitor
    #: (Node? node) -> void
    def visit(node)
      return unless node

      case node
      when BlankLine
        visit_blank_line(node)
      when RBSComment
        visit_rbs_comment(node)
      when Comment
        visit_comment(node)
      when TEnum
        visit_tenum(node)
      when TStruct
        visit_tstruct(node)
      when Module
        visit_module(node)
      when Class
        visit_class(node)
      when SingletonClass
        visit_singleton_class(node)
      when Struct
        visit_struct(node)
      when Group
        visit_group(node)
      when VisibilityGroup
        visit_visibility_group(node)
      when ConflictTree
        visit_conflict_tree(node)
      when ScopeConflict
        visit_scope_conflict(node)
      when TEnumBlock
        visit_tenum_block(node)
      when Tree
        visit_tree(node)
      when Const
        visit_const(node)
      when AttrAccessor
        visit_attr_accessor(node)
      when AttrReader
        visit_attr_reader(node)
      when AttrWriter
        visit_attr_writer(node)
      when Method
        visit_method(node)
      when ReqParam
        visit_req_param(node)
      when OptParam
        visit_opt_param(node)
      when RestParam
        visit_rest_param(node)
      when KwParam
        visit_kw_param(node)
      when KwOptParam
        visit_kw_opt_param(node)
      when KwRestParam
        visit_kw_rest_param(node)
      when BlockParam
        visit_block_param(node)
      when Include
        visit_include(node)
      when Extend
        visit_extend(node)
      when Public
        visit_public(node)
      when Protected
        visit_protected(node)
      when Private
        visit_private(node)
      when Send
        visit_send(node)
      when KwArg
        visit_kw_arg(node)
      when Arg
        visit_arg(node)
      when Sig
        visit_sig(node)
      when SigParam
        visit_sig_param(node)
      when TEnumValue
        visit_tenum_value(node)
      when TStructConst
        visit_tstruct_const(node)
      when TStructProp
        visit_tstruct_prop(node)
      when Helper
        visit_helper(node)
      when TypeMember
        visit_type_member(node)
      when MixesInClassMethods
        visit_mixes_in_class_methods(node)
      when RequiresAncestor
        visit_requires_ancestor(node)
      else
        raise VisitorError, "Unhandled node: #{node.class}"
      end
    end

    #: (Array[Node] nodes) -> void
    def visit_all(nodes)
      nodes.each { |node| visit(node) }
    end

    #: (File file) -> void
    def visit_file(file)
      visit(file.root)
    end

    private

    #: (Comment node) -> void
    def visit_comment(node); end

    #: (RBSComment node) -> void
    def visit_rbs_comment(node); end

    #: (BlankLine node) -> void
    def visit_blank_line(node); end

    #: (Module node) -> void
    def visit_module(node); end

    #: (Class node) -> void
    def visit_class(node); end

    #: (SingletonClass node) -> void
    def visit_singleton_class(node); end

    #: (Struct node) -> void
    def visit_struct(node); end

    #: (Tree node) -> void
    def visit_tree(node); end

    #: (Const node) -> void
    def visit_const(node); end

    #: (AttrAccessor node) -> void
    def visit_attr_accessor(node); end

    #: (AttrReader node) -> void
    def visit_attr_reader(node); end

    #: (AttrWriter node) -> void
    def visit_attr_writer(node); end

    #: (Method node) -> void
    def visit_method(node); end

    #: (ReqParam node) -> void
    def visit_req_param(node); end

    #: (OptParam node) -> void
    def visit_opt_param(node); end

    #: (RestParam node) -> void
    def visit_rest_param(node); end

    #: (KwParam node) -> void
    def visit_kw_param(node); end

    #: (KwOptParam node) -> void
    def visit_kw_opt_param(node); end

    #: (KwRestParam node) -> void
    def visit_kw_rest_param(node); end

    #: (BlockParam node) -> void
    def visit_block_param(node); end

    #: (Include node) -> void
    def visit_include(node); end

    #: (Extend node) -> void
    def visit_extend(node); end

    #: (Public node) -> void
    def visit_public(node); end

    #: (Protected node) -> void
    def visit_protected(node); end

    #: (Private node) -> void
    def visit_private(node); end

    #: (Send node) -> void
    def visit_send(node); end

    #: (Arg node) -> void
    def visit_arg(node); end

    #: (KwArg node) -> void
    def visit_kw_arg(node); end

    #: (Sig node) -> void
    def visit_sig(node); end

    #: (SigParam node) -> void
    def visit_sig_param(node); end

    #: (TStruct node) -> void
    def visit_tstruct(node); end

    #: (TStructConst node) -> void
    def visit_tstruct_const(node); end

    #: (TStructProp node) -> void
    def visit_tstruct_prop(node); end

    #: (TEnum node) -> void
    def visit_tenum(node); end

    #: (TEnumBlock node) -> void
    def visit_tenum_block(node); end

    #: (TEnumValue node) -> void
    def visit_tenum_value(node); end

    #: (Helper node) -> void
    def visit_helper(node); end

    #: (TypeMember node) -> void
    def visit_type_member(node); end

    #: (MixesInClassMethods node) -> void
    def visit_mixes_in_class_methods(node); end

    #: (RequiresAncestor node) -> void
    def visit_requires_ancestor(node); end

    #: (Group node) -> void
    def visit_group(node); end

    #: (VisibilityGroup node) -> void
    def visit_visibility_group(node); end

    #: (ConflictTree node) -> void
    def visit_conflict_tree(node); end

    #: (ScopeConflict node) -> void
    def visit_scope_conflict(node); end
  end
end

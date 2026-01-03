# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    class AddSigTemplates < Visitor
      #: (?with_todo_comment: bool) -> void
      def initialize(with_todo_comment: true)
        super()
        @with_todo_comment = with_todo_comment
      end

      # @override
      #: (Node? node) -> void
      def visit(node)
        case node
        when Tree
          visit_all(node.nodes)
        when Attr
          add_attr_sig(node)
        when Method
          add_method_sig(node)
        end
      end

      private

      #: (Attr attr) -> void
      def add_attr_sig(attr)
        return unless attr.sigs.empty?
        return if attr.names.size > 1

        params = []
        params << SigParam.new(attr.names.first.to_s, "T.untyped") if attr.is_a?(AttrWriter)

        attr.sigs << Sig.new(
          params: params,
          return_type: "T.untyped",
        )
        add_todo_comment(attr)
      end

      #: (Method method) -> void
      def add_method_sig(method)
        return unless method.sigs.empty?

        method.sigs << Sig.new(
          params: method.params.map { |param| SigParam.new(param.name, "T.untyped") },
          return_type: "T.untyped",
        )
        add_todo_comment(method)
      end

      #: (NodeWithComments node) -> void
      def add_todo_comment(node)
        node.comments << Comment.new("TODO: fill in signature with appropriate type information") if @with_todo_comment
      end
    end
  end

  class Tree
    #: (?with_todo_comment: bool) -> void
    def add_sig_templates!(with_todo_comment: true)
      visitor = Rewriters::AddSigTemplates.new(with_todo_comment: with_todo_comment)
      visitor.visit(self)
    end
  end
end

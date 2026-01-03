# typed: strict
# frozen_string_literal: true

module RBI
  class UnexpectedMultipleSigsError < Error
    #: Node
    attr_reader :node

    #: (Node node) -> void
    def initialize(node)
      super(<<~MSG)
        This declaration cannot have more than one sig.

        #{node.string.chomp}
      MSG

      @node = node
    end
  end

  module Rewriters
    class AttrToMethods < Visitor
      # @override
      #: (Node? node) -> void
      def visit(node)
        case node
        when Tree
          visit_all(node.nodes.dup)

        when Attr
          replace(node, with: node.convert_to_methods)
        end
      end

      private

      #: (Node node, with: Array[Node]) -> void
      def replace(node, with:)
        tree = node.parent_tree
        raise ReplaceNodeError, "Can't replace #{self} without a parent tree" unless tree

        node.detach
        with.each { |node| tree << node }
      end
    end
  end

  class Tree
    #: -> void
    def replace_attributes_with_methods!
      visitor = Rewriters::AttrToMethods.new
      visitor.visit(self)
    end
  end

  class Attr
    # @abstract
    #: -> Array[Method]
    def convert_to_methods = raise NotImplementedError, "Abstract method called"

    private

    # @final
    #: -> [Sig?, (Type | String)?]
    def parse_sig
      raise UnexpectedMultipleSigsError, self if 1 < sigs.count

      sig = sigs.first
      return [nil, nil] unless sig

      attribute_type = case self
      when AttrReader, AttrAccessor then sig.return_type
      when AttrWriter then sig.params.first&.type
      end

      [sig, attribute_type]
    end

    #: (String name, Sig? sig, Visibility visibility, Loc? loc, Array[Comment] comments) -> Method
    def create_getter_method(name, sig, visibility, loc, comments)
      Method.new(
        name,
        params: [],
        visibility: visibility,
        sigs: sig ? [sig] : [],
        loc: loc,
        comments: comments,
      )
    end

    #: (
    #|   String name,
    #|   Sig? sig,
    #|   (Type | String)? attribute_type,
    #|   Visibility visibility,
    #|   Loc? loc,
    #|   Array[Comment] comments
    #| ) -> Method
    def create_setter_method(name, sig, attribute_type, visibility, loc, comments) # rubocop:disable Metrics/ParameterLists
      sig = if sig # Modify the original sig to correct the name, and remove the return type
        params = attribute_type ? [SigParam.new(name, attribute_type)] : []

        Sig.new(
          params: params,
          return_type: "void",
          is_abstract: sig.is_abstract,
          is_override: sig.is_override,
          is_overridable: sig.is_overridable,
          is_final: sig.is_final,
          type_params: sig.type_params,
          checked: sig.checked,
          loc: sig.loc,
        )
      end

      Method.new(
        "#{name}=",
        params: [ReqParam.new(name)],
        visibility: visibility,
        sigs: sig ? [sig] : [],
        loc: loc,
        comments: comments,
      )
    end
  end

  class AttrAccessor
    # @override
    #: -> Array[Method]
    def convert_to_methods
      sig, attribute_type = parse_sig

      names.flat_map do |name|
        [
          create_getter_method(name.to_s, sig, visibility, loc, comments),
          create_setter_method(name.to_s, sig, attribute_type, visibility, loc, comments),
        ]
      end
    end
  end

  class AttrReader
    # @override
    #: -> Array[Method]
    def convert_to_methods
      sig, _ = parse_sig

      names.map { |name| create_getter_method(name.to_s, sig, visibility, loc, comments) }
    end
  end

  class AttrWriter
    # @override
    #: -> Array[Method]
    def convert_to_methods
      sig, attribute_type = parse_sig

      names.map { |name| create_setter_method(name.to_s, sig, attribute_type, visibility, loc, comments) }
    end
  end
end

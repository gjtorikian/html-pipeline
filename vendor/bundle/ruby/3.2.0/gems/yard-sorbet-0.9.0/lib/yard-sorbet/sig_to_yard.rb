# typed: strict
# frozen_string_literal: true

module YARDSorbet
  # Translate `sig` type syntax to `YARD` type syntax.
  module SigToYARD
    class << self
      extend T::Sig

      # Map of common types to YARD conventions (in order to reduce allocations)
      REF_TYPES = T.let({
        'T::Boolean' => ['Boolean'].freeze, # YARD convention for booleans
        # YARD convention is to use singleton objects when applicable:
        # https://www.rubydoc.info/gems/yard/file/docs/Tags.md#literals
        'FalseClass' => ['false'].freeze,
        'NilClass' => ['nil'].freeze,
        'TrueClass' => ['true'].freeze
      }.freeze, T::Hash[String, [String]])
      private_constant :REF_TYPES

      # @see https://yardoc.org/types.html
      sig { params(node: YARD::Parser::Ruby::AstNode).returns(T::Array[String]) }
      def convert(node) = convert_node(node).map { _1.gsub(/\n\s*/, ' ') }

      private

      sig { params(node: YARD::Parser::Ruby::AstNode).returns(T::Array[String]) }
      def convert_node(node)
        case node
        when YARD::Parser::Ruby::MethodCallNode
          node.namespace.source == 'T' ? convert_t_method(node) : [node.source]
        when YARD::Parser::Ruby::ReferenceNode
          node_source = node.source
          REF_TYPES[node_source] || [node_source]
        else convert_node_type(node)
        end
      end

      sig { params(node: YARD::Parser::Ruby::AstNode).returns(T::Array[String]) }
      def convert_node_type(node)
        case node.type
        when :aref then convert_aref(node)
        when :arg_paren then convert_node(node.first)
        when :array then convert_array(node)
        # Fixed hashes as return values are unsupported:
        # https://github.com/lsegal/yard/issues/425
        #
        # Hash key params can be individually documented with `@option`, but
        # sig translation is currently unsupported.
        when :hash then ['Hash']
        # seen when sig methods omit parentheses
        when :list then convert_list(node)
        else convert_unknown(node)
        end
      end

      sig { params(node: YARD::Parser::Ruby::AstNode).returns(String) }
      def build_generic_type(node)
        return node.source if node.empty? || node.type != :aref

        collection_type = node.first.source
        member_type = node.last.children.map { build_generic_type(_1) }.join(', ')
        "#{collection_type}[#{member_type}]"
      end

      sig { params(node: YARD::Parser::Ruby::AstNode).returns(T::Array[String]) }
      def convert_aref(node)
        # https://www.rubydoc.info/gems/yard/file/docs/Tags.md#parametrized-types
        case node.first.source
        when 'T::Array', 'T::Enumerable', 'T::Range', 'T::Set' then convert_collection(node)
        when 'T::Hash' then convert_hash(node)
        else
          log.info("Unsupported sig aref node #{node.source}")
          [build_generic_type(node)]
        end
      end

      sig { params(node: YARD::Parser::Ruby::AstNode).returns([String]) }
      def convert_array(node)
        # https://www.rubydoc.info/gems/yard/file/docs/Tags.md#order-dependent-lists
        member_types = node.first.children.map { convert_node(_1) }
        sequence = member_types.map { _1.size == 1 ? _1[0] : _1.to_s.tr('"', '') }.join(', ')
        ["Array<(#{sequence})>"]
      end

      sig { params(node: YARD::Parser::Ruby::AstNode).returns([String]) }
      def convert_collection(node)
        collection_type = node.first.source.split('::').last
        member_type = convert_node(node[-1][0]).join(', ')
        ["#{collection_type}<#{member_type}>"]
      end

      sig { params(node: YARD::Parser::Ruby::AstNode).returns([String]) }
      def convert_hash(node)
        kv = node.last.children
        key_type = convert_node(kv.first).join(', ')
        value_type = convert_node(kv.last).join(', ')
        ["Hash{#{key_type} => #{value_type}}"]
      end

      sig { params(node: YARD::Parser::Ruby::AstNode).returns(T::Array[String]) }
      def convert_list(node)
        node.children.size == 1 ? convert_node(node.children.first) : [node.source]
      end

      sig { params(node: YARD::Parser::Ruby::MethodCallNode).returns(T::Array[String]) }
      def convert_t_method(node)
        case node.method_name(true)
        # Order matters here, putting `nil` last results in a more concise return syntax in the UI (superscripted `?`):
        # https://github.com/lsegal/yard/blob/cfa62ae/lib/yard/templates/helpers/html_helper.rb#L499-L500
        when :nilable then convert_node(node.last) + REF_TYPES.fetch('NilClass')
        when :any then node[-1][0].children.flat_map { convert_node(_1) }
        else [node.source]
        end
      end

      sig { params(node: YARD::Parser::Ruby::AstNode).returns([String]) }
      def convert_unknown(node)
        log.warn("Unsupported sig #{node.type} node #{node.source}")
        [node.source]
      end
    end
  end
end

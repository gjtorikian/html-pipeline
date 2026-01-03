# typed: strict
# frozen_string_literal: true

module RBI
  class Type
    class Error < RBI::Error; end

    class << self
      #: (String string) -> Type
      def parse_string(string)
        result = Prism.parse(string)
        unless result.success?
          raise Error, result.errors.map { |e| "#{e.message}." }.join(" ")
        end

        node = result.value
        raise Error, "Expected a type expression, got `#{node.class}`" unless node.is_a?(Prism::ProgramNode)
        raise Error, "Expected a type expression, got nothing" if node.statements.body.empty?
        raise Error, "Expected a single type expression, got `#{node.slice}`" if node.statements.body.size > 1

        node = node.statements.body.first #: as !nil
        parse_node(node)
      end

      #: (Prism::Node node) -> Type
      def parse_node(node)
        case node
        when Prism::ConstantReadNode, Prism::ConstantPathNode
          parse_constant(node)
        when Prism::ConstantWriteNode, Prism::ConstantPathWriteNode
          parse_constant_assignment(node)
        when Prism::CallNode
          parse_call(node)
        when Prism::ArrayNode
          parse_tuple(node)
        when Prism::HashNode, Prism::KeywordHashNode
          parse_shape(node)
        when Prism::ParenthesesNode
          body = node.body
          raise Error, "Expected exactly 1 child, got 0" unless body.is_a?(Prism::StatementsNode)

          children = body.body
          raise Error, "Expected exactly 1 child, got #{children.size}" unless children.size == 1

          parse_node(
            children.first, #: as !nil
          )
        else
          raise Error, "Unexpected node `#{node}`"
        end
      end

      private

      #: ((Prism::ConstantReadNode | Prism::ConstantPathNode) node) -> Type
      def parse_constant(node)
        case node
        when Prism::ConstantReadNode
          # `Foo`
          Type::Simple.new(node.slice)
        when Prism::ConstantPathNode
          if t_boolean?(node)
            # `T::Boolean` or `::T::Boolean`
            Type::Boolean.new
          else
            # `::Foo` or `::Foo::Bar`
            Type::Simple.new(node.slice)
          end
        end
      end

      #: (Prism::ConstantWriteNode | Prism::ConstantPathWriteNode node) -> Type
      def parse_constant_assignment(node)
        if t_type_alias?(node.value)
          value = node.value #: as Prism::CallNode
          name = if node.is_a?(Prism::ConstantPathWriteNode)
            node.target.full_name
          else
            node.full_name
          end

          body = value.block

          if body.is_a?(Prism::BlockNode) && (stmts = body.body).is_a?(Prism::StatementsNode)
            body_node = stmts.body.first #: as !nil
            Type::TypeAlias.new(name, parse_node(body_node))
          else
            Type::Simple.new(node.slice)
          end
        else
          Type::Simple.new(node.slice)
        end
      end

      #: (Prism::CallNode node) -> Type
      def parse_call(node)
        recv = node.receiver

        case node.name
        when :void
          # `void`
          check_arguments_exactly!(node, 0)
          return Type::Void.new if recv.nil?
        when :[]
          case recv
          when Prism::ConstantReadNode
            # `Foo[Bar]` or `Foo[Bar, Baz]`
            args = check_arguments_at_least!(node, 1)
            return Type::Generic.new(recv.slice, *args.map { |arg| parse_node(arg) })
          when Prism::ConstantPathNode
            if t_class?(recv)
              # `T::Class[Foo]` or `::T::Class[Foo]`
              args = check_arguments_exactly!(node, 1)
              return Type::Class.new(
                parse_node(
                  args.first, #: as !nil
                ),
              )
            elsif t_module?(recv)
              # `T::Module[Foo]` or `::T::Module[Foo]`
              args = check_arguments_exactly!(node, 1)
              return Type::Module.new(
                parse_node(
                  args.first, #: as !nil
                ),
              )
            else
              # `::Foo[Bar]` or `::Foo[Bar, Baz]`
              args = check_arguments_at_least!(node, 1)
              return Type::Generic.new(recv.slice, *args.map { |arg| parse_node(arg) })
            end
          when Prism::CallNode
            # `T.class_of(Foo)[Bar]`
            if t_class_of?(recv)
              type_args = check_arguments_exactly!(recv, 1)
              type = parse_node(
                type_args.first, #: as !nil
              )
              raise Error, "Expected a simple type, got `#{type}`" unless type.is_a?(Type::Simple)

              type_param_args = check_arguments_exactly!(node, 1)
              type_param = parse_node(
                type_param_args.first, #: as !nil
              )
              return Type::ClassOf.new(type, type_param)
            end
          end

          # `something[]`
          raise Error, "Unexpected expression `#{node.slice}`"
        end

        # `T.proc`
        return parse_proc(node) if t_proc?(node)

        # `Foo.nilable` or anything called on a constant that is not `::T`
        raise Error, "Unexpected expression `#{node.slice}`" unless t?(recv)

        case node.name
        when :nilable
          # `T.nilable(Foo)`
          args = check_arguments_exactly!(node, 1)
          type = parse_node(
            args.first, #: as !nil
          )
          Type::Nilable.new(type)
        when :anything
          # `T.anything`
          check_arguments_exactly!(node, 0)
          Type::Anything.new
        when :untyped
          # `T.untyped`
          check_arguments_exactly!(node, 0)
          Type::Untyped.new
        when :noreturn
          # `T.noreturn`
          check_arguments_exactly!(node, 0)
          Type::NoReturn.new
        when :self_type
          # `T.self_type`
          check_arguments_exactly!(node, 0)
          Type::SelfType.new
        when :attached_class
          # `T.attached_class`
          check_arguments_exactly!(node, 0)
          Type::AttachedClass.new
        when :class_of
          # `T.class_of(Foo)`
          args = check_arguments_exactly!(node, 1)
          type = parse_node(
            args.first, #: as !nil
          )
          raise Error, "Expected a simple type, got `#{type}`" unless type.is_a?(Type::Simple)

          Type::ClassOf.new(type)
        when :all
          # `T.all(Foo, Bar)`
          args = check_arguments_at_least!(node, 2)
          Type::All.new(args.map { |arg| parse_node(arg) })
        when :any
          # `T.any(Foo, Bar)`
          args = check_arguments_at_least!(node, 2)
          Type::Any.new(args.map { |arg| parse_node(arg) })
        when :type_parameter
          # `T.type_parameter(:T)`
          args = check_arguments_exactly!(node, 1)
          symbol = args.first
          raise Error, "Expected a symbol, got `#{symbol&.slice || "nil"}`" unless symbol.is_a?(Prism::SymbolNode)

          Type::TypeParameter.new(symbol.slice.delete_prefix(":").to_sym)
        else
          # `T.something`
          raise Error, "Unexpected expression `#{node.slice}`"
        end
      end

      #: (Prism::ArrayNode node) -> Type
      def parse_tuple(node)
        Type.tuple(*node.elements.map { |elem| parse_node(elem) })
      end

      #: ((Prism::HashNode | Prism::KeywordHashNode) node) -> Type
      def parse_shape(node)
        hash = node.elements.map do |elem|
          raise Error, "Expected key-value pair, got `#{elem.slice}`" unless elem.is_a?(Prism::AssocNode)

          elem_key = elem.key
          key = case elem_key
          when Prism::SymbolNode
            elem_key
              .value #: as !nil
              .to_sym
          when Prism::StringNode
            elem_key.content
          else
            raise Error, "Expected symbol or string, got `#{elem_key.slice}`"
          end
          [key, parse_node(elem.value)]
        end.to_h
        Type.shape(**hash)
      end

      #: (Prism::CallNode node) -> Type
      def parse_proc(node)
        calls = call_chain(node).reverse
        calls.pop # remove `T.`

        raise Error, "Unexpected expression `#{node.slice}`" if calls.empty?

        type = Type::Proc.new
        calls.each do |call|
          raise Error, "Unexpected expression `#{node.slice}`..." unless call.is_a?(Prism::CallNode)

          case call.name
          when :params
            args = call.arguments&.arguments || []
            hash = args.first
            raise Error, "Expected hash, got `#{hash.class}`" unless hash.is_a?(Prism::KeywordHashNode)

            params = hash.elements.map do |elem|
              raise Error, "Expected key-value pair, got `#{elem.slice}`" unless elem.is_a?(Prism::AssocNode)

              [elem.key.slice.delete_suffix(":").to_sym, parse_node(elem.value)]
            end.to_h
            type.params(
              **params, #: untyped
            )
          when :returns
            args = check_arguments_exactly!(call, 1)
            type.returns(
              parse_node(
                args.first, #: as !nil
              ),
            )
          when :void
            type.void
          when :proc
            return type
          when :bind
            args = check_arguments_exactly!(call, 1)
            type.bind(
              parse_node(
                args.first, #: as !nil
              ),
            )
          else
            raise Error, "Unexpected expression `#{node.slice}`"
          end
        end
        type
      end

      #: (Prism::CallNode node, Integer count) -> Array[Prism::Node]
      def check_arguments_exactly!(node, count)
        args = node.arguments&.arguments || []
        unless args.size == count
          if count == 0
            raise Error, "Expected no arguments, got #{args.size}"
          elsif count == 1
            raise Error, "Expected exactly 1 argument, got #{args.size}"
          else
            raise Error, "Expected exactly #{count} arguments, got #{args.size}"
          end
        end
        args
      end

      #: (Prism::CallNode node, Integer count) -> Array[Prism::Node]
      def check_arguments_at_least!(node, count)
        args = node.arguments&.arguments || []
        if args.size < count
          if count == 1
            raise Error, "Expected at least 1 argument, got #{args.size}"
          else
            raise Error, "Expected at least #{count} arguments, got #{args.size}"
          end
        end
        args
      end

      #: (Prism::CallNode node) -> Array[Prism::Node]
      def call_chain(node)
        call_chain = [node] #: Array[Prism::Node]
        receiver = node.receiver #: Prism::Node?
        while receiver
          call_chain.prepend(receiver)
          break unless receiver.is_a?(Prism::CallNode)

          receiver = receiver.receiver
        end
        call_chain
      end

      #: (Prism::Node? node) -> bool
      def t?(node)
        case node
        when Prism::ConstantReadNode
          return true if node.name == :T
        when Prism::ConstantPathNode
          return true if node.parent.nil? && node.name == :T
        end

        false
      end

      #: (Prism::Node? node) -> bool
      def t_type_alias?(node)
        return false unless node.is_a?(Prism::CallNode)

        t?(node.receiver) && node.name == :type_alias
      end

      #: (Prism::Node? node) -> bool
      def t_boolean?(node)
        return false unless node.is_a?(Prism::ConstantPathNode)

        t?(node.parent) && node.name == :Boolean
      end

      #: (Prism::ConstantPathNode node) -> bool
      def t_class?(node)
        t?(node.parent) && node.name == :Class
      end

      #: (Prism::ConstantPathNode node) -> bool
      def t_module?(node)
        t?(node.parent) && node.name == :Module
      end

      #: (Prism::Node? node) -> bool
      def t_class_of?(node)
        return false unless node.is_a?(Prism::CallNode)

        t?(node.receiver) && node.name == :class_of
      end

      #: (Prism::CallNode node) -> bool
      def t_proc?(node)
        chain = call_chain(node)
        return false if chain.size < 2
        return false unless t?(chain[0])

        second = chain[1]
        return false unless second.is_a?(Prism::CallNode)
        return false unless second.name == :proc

        true
      end
    end
  end
end

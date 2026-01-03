# typed: strict
# frozen_string_literal: true

module RBI
  class Type
    class Visitor
      class Error < RBI::Error; end

      #: (Type node) -> void
      def visit(node)
        case node
        when Type::Simple
          visit_simple(node)
        when Type::Void
          visit_void(node)
        when Type::Boolean
          visit_boolean(node)
        when Type::Nilable
          visit_nilable(node)
        when Type::Untyped
          visit_untyped(node)
        when Type::Generic
          visit_generic(node)
        when Type::Anything
          visit_anything(node)
        when Type::NoReturn
          visit_no_return(node)
        when Type::SelfType
          visit_self_type(node)
        when Type::AttachedClass
          visit_attached_class(node)
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
        when Type::TypeAlias
          visit_type_alias(node)
        else
          raise Error, "Unhandled node: #{node.class}"
        end
      end

      private

      #: (Type::All type) -> void
      def visit_all(type); end

      #: (Type::Any type) -> void
      def visit_any(type); end

      #: (Type::Anything type) -> void
      def visit_anything(type); end

      #: (Type::AttachedClass type) -> void
      def visit_attached_class(type); end

      #: (Type::Boolean type) -> void
      def visit_boolean(type); end

      #: (Type::Class type) -> void
      def visit_class(type); end

      #: (Type::ClassOf type) -> void
      def visit_class_of(type); end

      #: (Type::Generic type) -> void
      def visit_generic(type); end

      #: (Type::Nilable type) -> void
      def visit_nilable(type); end

      #: (Type::Simple type) -> void
      def visit_simple(type); end

      #: (Type::NoReturn type) -> void
      def visit_no_return(type); end

      #: (Type::Proc type) -> void
      def visit_proc(type); end

      #: (Type::SelfType type) -> void
      def visit_self_type(type); end

      #: (Type::Void type) -> void
      def visit_void(type); end

      #: (Type::Shape type) -> void
      def visit_shape(type); end

      #: (Type::Tuple type) -> void
      def visit_tuple(type); end

      #: (Type::TypeParameter type) -> void
      def visit_type_parameter(type); end

      #: (Type::Untyped type) -> void
      def visit_untyped(type); end

      #: (Type::TypeAlias type) -> void
      def visit_type_alias(type); end
    end
  end
end

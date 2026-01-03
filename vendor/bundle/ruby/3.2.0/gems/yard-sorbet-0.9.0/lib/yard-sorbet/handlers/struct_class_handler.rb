# typed: strict
# frozen_string_literal: true

module YARDSorbet
  module Handlers
    # Class-level handler that folds all `const` and `prop` declarations into the constructor documentation
    # this needs to be injected as a module otherwise the default Class handler will overwrite documentation
    #
    # @note this module is included in `YARD::Handlers::Ruby::ClassHandler`
    module StructClassHandler
      extend T::Sig

      sig { void }
      def process
        super
        return if extra_state.prop_docs.nil?

        # lookup the full YARD path for the current class
        class_ns = YARD::CodeObjects::ClassObject.new(namespace, statement[0].source.gsub(/\s/, ''))
        props = extra_state.prop_docs[class_ns]
        return if props.empty?

        process_t_struct_props(props, class_ns)
      end

      private

      # Create a virtual `initialize` method with all the `prop`/`const` arguments
      sig { params(props: T::Array[TStructProp], class_ns: YARD::CodeObjects::ClassObject).void }
      def process_t_struct_props(props, class_ns)
        # having the name :initialize & the scope :instance marks this as the constructor.
        object = YARD::CodeObjects::MethodObject.new(class_ns, :initialize, :instance)
        # There is a chance that there is a custom initializer, so make sure we steal the existing docstring
        # and source
        docstring, directives = Directives.extract_directives(object.docstring)
        object.tags.each { docstring.add_tag(_1) }
        props.each { TagUtils.upsert_tag(docstring, 'param', _1.types, _1.prop_name, _1.doc) }
        TagUtils.upsert_tag(docstring, 'return', TagUtils::VOID_RETURN_TYPE)
        decorate_t_struct_init(object, props, docstring, directives)
      end

      sig do
        params(
          object: YARD::CodeObjects::MethodObject,
          props: T::Array[TStructProp],
          docstring: YARD::Docstring,
          directives: T::Array[String]
        ).void
      end
      def decorate_t_struct_init(object, props, docstring, directives)
        # Use kwarg style arguments, with optionals being marked with a default (unless an actual default was specified)
        object.parameters = to_object_parameters(props)
        # The "source" of our constructor is the field declarations
        object.source ||= props.map(&:source).join("\n")
        object.docstring = docstring
        Directives.add_directives(object.docstring, directives)
      end

      sig { params(props: T::Array[TStructProp]).returns(T::Array[[String, T.nilable(String)]]) }
      def to_object_parameters(props)
        props.map do |prop|
          default = prop.default || (prop.types.include?('nil') ? 'nil' : nil)
          ["#{prop.prop_name}:", default]
        end
      end
    end
  end
end

YARD::Handlers::Ruby::ClassHandler.include YARDSorbet::Handlers::StructClassHandler

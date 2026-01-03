# typed: strict
# frozen_string_literal: true

module RBI
  module RBS
    class TypeTranslator
      class << self
        #: (
        #|   ::RBS::Types::Alias |
        #|   ::RBS::Types::Bases::Any |
        #|   ::RBS::Types::Bases::Bool |
        #|   ::RBS::Types::Bases::Bottom |
        #|   ::RBS::Types::Bases::Class |
        #|   ::RBS::Types::Bases::Instance |
        #|   ::RBS::Types::Bases::Nil |
        #|   ::RBS::Types::Bases::Self |
        #|   ::RBS::Types::Bases::Top |
        #|   ::RBS::Types::Bases::Void |
        #|   ::RBS::Types::ClassSingleton |
        #|   ::RBS::Types::ClassInstance |
        #|   ::RBS::Types::Function |
        #|   ::RBS::Types::Interface |
        #|   ::RBS::Types::Intersection |
        #|   ::RBS::Types::Literal |
        #|   ::RBS::Types::Optional |
        #|   ::RBS::Types::Proc |
        #|   ::RBS::Types::Record |
        #|   ::RBS::Types::Tuple |
        #|   ::RBS::Types::Union |
        #|   ::RBS::Types::UntypedFunction |
        #|   ::RBS::Types::Variable
        #| ) -> Type
        def translate(type)
          case type
          when ::RBS::Types::Alias
            translate_type_alias(type)
          when ::RBS::Types::Bases::Any
            Type.untyped
          when ::RBS::Types::Bases::Bool
            Type.boolean
          when ::RBS::Types::Bases::Bottom
            Type.noreturn
          when ::RBS::Types::Bases::Class
            # TODO: unsupported yet
            Type.untyped
          when ::RBS::Types::Bases::Instance
            Type.attached_class
          when ::RBS::Types::Bases::Nil
            Type.simple("NilClass")
          when ::RBS::Types::Bases::Self
            Type.self_type
          when ::RBS::Types::Bases::Top
            Type.anything
          when ::RBS::Types::Bases::Void
            Type.void
          when ::RBS::Types::ClassSingleton
            Type.class_of(Type.simple(type.name.to_s))
          when ::RBS::Types::ClassInstance
            translate_class_instance(type)
          when ::RBS::Types::Function
            translate_function(type)
          when ::RBS::Types::Interface
            # TODO: unsupported yet
            Type.untyped
          when ::RBS::Types::Intersection
            Type.all(*type.types.map { |t| translate(t) })
          when ::RBS::Types::Literal
            # TODO: unsupported yet
            Type.untyped
          when ::RBS::Types::Optional
            Type.nilable(translate(type.type))
          when ::RBS::Types::Proc
            proc = translate(type.type) #: as Type::Proc
            proc.bind(translate(type.self_type)) if type.self_type
            proc
          when ::RBS::Types::Record
            Type.shape(type.fields.map { |name, type| [name, translate(type)] }.to_h)
          when ::RBS::Types::Tuple
            Type.tuple(type.types.map { |t| translate(t) })
          when ::RBS::Types::Union
            Type.any(*type.types.map { |t| translate(t) })
          when ::RBS::Types::UntypedFunction
            Type.proc.params(arg0: Type.untyped).returns(Type.untyped)
          when ::RBS::Types::Variable
            Type.type_parameter(type.name)
          else
            type #: absurd
          end
        end

        private

        #: (::RBS::Types::Alias) -> Type
        def translate_type_alias(type)
          name = ::RBS::TypeName.new(
            namespace: type.name.namespace,
            name: type.name.name.to_s.gsub(/(?:^|_)([a-z\d]*)/i) do |match|
              match = match.delete_prefix("_")
              !match.empty? ? match[0].upcase.concat(match[1..-1]) : +""
            end,
          )
          Type.simple(name.to_s)
        end

        #: (::RBS::Types::ClassInstance) -> Type
        def translate_class_instance(type)
          return Type.simple(type.name.to_s) if type.args.empty?

          type_name = translate_t_generic_type(type.name.to_s)
          Type.generic(type_name, *type.args.map { |arg| translate(arg) })
        end

        #: (::RBS::Types::Function) -> Type
        def translate_function(type)
          proc = Type.proc

          index = 0

          type.required_positionals.each do |param|
            proc.proc_params[param.name || :"arg#{index}"] = translate(param.type)
            index += 1
          end

          type.optional_positionals.each do |param|
            proc.proc_params[param.name || :"arg#{index}"] = translate(param.type)
            index += 1
          end

          rest_positional = type.rest_positionals
          if rest_positional
            proc.proc_params[rest_positional.name || :"arg#{index}"] = translate(rest_positional.type)
            index += 1
          end

          type.trailing_positionals.each do |param|
            proc.proc_params[param.name || :"arg#{index}"] = translate(param.type)
            index += 1
          end

          type.required_keywords.each do |name, param|
            proc.proc_params[name.to_sym] = translate(param.type)
            index += 1
          end

          type.optional_keywords.each do |name, param|
            proc.proc_params[name.to_sym] = translate(param.type)
            index += 1
          end

          rest_keyword = type.rest_keywords
          if rest_keyword
            proc.proc_params[rest_keyword.name || :"arg_#{index}"] = translate(rest_keyword.type)
            index += 1
          end

          proc.returns(translate(type.return_type))
          proc
        end

        #: (String type_name) -> String
        def translate_t_generic_type(type_name)
          case type_name.delete_prefix("::")
          when "Array"
            "::T::Array"
          when "Class"
            "::T::Class"
          when "Enumerable"
            "::T::Enumerable"
          when "Enumerator"
            "::T::Enumerator"
          when "Enumerator::Chain"
            "::T::Enumerator::Chain"
          when "Enumerator::Lazy"
            "::T::Enumerator::Lazy"
          when "Hash"
            "::T::Hash"
          when "Module"
            "::T::Module"
          when "Set"
            "::T::Set"
          when "Range"
            "::T::Range"
          else
            type_name
          end
        end
      end
    end
  end
end

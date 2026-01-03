# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetTypeVariables < Base
        extend T::Sig

        include Runtime::Reflection

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          constant = event.constant
          node = event.node

          compile_type_variable_declarations(node, constant)

          sclass = RBI::SingletonClass.new
          compile_type_variable_declarations(sclass, singleton_class_of(constant))
          node << sclass if sclass.nodes.length > 1
        end

        sig { params(tree: RBI::Tree, constant: Module).void }
        def compile_type_variable_declarations(tree, constant)
          # Try to find the type variables defined on this constant, bail if we can't
          type_variables = Runtime::GenericTypeRegistry.lookup_type_variables(constant)
          return unless type_variables

          # Map each type variable to its string representation.
          #
          # Each entry of `type_variables` maps a Module to a String, or
          # is a `has_attached_class!` declaration, and the order they are inserted
          # into the hash is the order they should be defined in the source code.
          type_variable_declarations = type_variables.filter_map do |type_variable|
            node = node_from_type_variable(type_variable)
            next unless node

            tree << node
          end

          return if type_variable_declarations.empty?

          tree << RBI::Extend.new("T::Generic")
        end

        sig { params(type_variable: Tapioca::TypeVariableModule).returns(T.nilable(RBI::Node)) }
        def node_from_type_variable(type_variable)
          case type_variable.type
          when Tapioca::TypeVariableModule::Type::HasAttachedClass
            RBI::Send.new(type_variable.serialize)
          else
            type_variable_name = type_variable.name
            return unless type_variable_name

            RBI::TypeMember.new(type_variable_name, type_variable.serialize)
          end
        end

        sig { override.params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

module YARDSorbet
  module Handlers
    # Extends any modules included via `mixes_in_class_methods`
    # @see https://sorbet.org/docs/abstract#interfaces-and-the-included-hook
    #   Sorbet `mixes_in_class_methods` documentation
    class IncludeHandler < YARD::Handlers::Ruby::Base
      extend T::Sig

      handles method_call(:include)
      namespace_only

      sig { void }
      def process
        statement.parameters(false).each do |mixin|
          obj = YARD::CodeObjects::Proxy.new(namespace, mixin.source)
          class_methods_namespaces = MixesInClassMethodsHandler.mixed_in_class_methods(obj.to_s)
          class_methods_namespaces&.each { included_in.mixins(:class) << YARD::CodeObjects::Proxy.new(obj, _1) }
        end
      end

      private

      # @return the namespace object that is including the module
      sig { returns(YARD::CodeObjects::NamespaceObject) }
      def included_in
        statement.namespace ? YARD::CodeObjects::Proxy.new(namespace, statement.namespace.source) : namespace
      end
    end
  end
end

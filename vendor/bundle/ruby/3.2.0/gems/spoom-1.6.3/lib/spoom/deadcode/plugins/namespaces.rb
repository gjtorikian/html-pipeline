# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Namespaces < Base
        # @override
        #: (Model::Class definition) -> void
        def on_define_class(definition)
          @index.ignore(definition) if used_as_namespace?(definition)
        end

        # @override
        #: (Model::Module definition) -> void
        def on_define_module(definition)
          @index.ignore(definition) if used_as_namespace?(definition)
        end

        private

        #: (Model::Namespace symbol_def) -> bool
        def used_as_namespace?(symbol_def)
          symbol_def.children.any?
        end
      end
    end
  end
end

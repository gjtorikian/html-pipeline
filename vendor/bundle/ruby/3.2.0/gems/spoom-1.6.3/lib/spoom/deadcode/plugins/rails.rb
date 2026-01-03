# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rails < Base
        ignore_constants_named("APP_PATH", "ENGINE_PATH", "ENGINE_ROOT")

        # @override
        #: (Model::Class definition) -> void
        def on_define_class(definition)
          @index.ignore(definition) if file_is_helper?(definition)
        end

        # @override
        #: (Model::Module definition) -> void
        def on_define_module(definition)
          @index.ignore(definition) if file_is_helper?(definition)
        end

        private

        #: (Model::Namespace symbol_def) -> bool
        def file_is_helper?(symbol_def)
          symbol_def.location.file.match?(%r{app/helpers/.*\.rb$})
        end
      end
    end
  end
end

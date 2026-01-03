# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Minitest < Base
        ignore_classes_named(/Test$/)

        ignore_methods_named(
          "after_all",
          "around",
          "around_all",
          "before_all",
          "setup",
          "teardown",
        )

        # @override
        #: (Model::Method definition) -> void
        def on_define_method(definition)
          file = definition.location.file
          @index.ignore(definition) if file.match?(%r{test/.*test\.rb$}) && definition.name.match?(/^test_/)
        end

        # @override
        #: (Send send) -> void
        def on_send(send)
          case send.name
          when "assert_predicate", "refute_predicate"
            name = send.args[1]&.slice
            return unless name

            @index.reference_method(name.delete_prefix(":"), send.location)
          end
        end
      end
    end
  end
end

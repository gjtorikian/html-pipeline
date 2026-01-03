# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionMailerPreview < Base
        ignore_classes_inheriting_from("ActionMailer::Preview")

        # @override
        #: (Model::Method definition) -> void
        def on_define_method(definition)
          owner = definition.owner
          return unless owner.is_a?(Model::Class)

          superclass_name = owner.superclass_name
          return unless superclass_name

          @index.ignore(definition) if superclass_name == "ActionMailer::Preview"
        end
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionPack < Base
        ignore_classes_inheriting_from("ApplicationController")

        CALLBACKS = [
          "after_action",
          "append_after_action",
          "append_around_action",
          "append_before_action",
          "around_action",
          "before_action",
          "prepend_after_action",
          "prepend_around_action",
          "prepend_before_action",
          "skip_after_action",
          "skip_around_action",
          "skip_before_action",
        ].freeze #: Array[String]

        # @override
        #: (Model::Method definition) -> void
        def on_define_method(definition)
          owner = definition.owner
          return unless owner.is_a?(Model::Class)

          @index.ignore(definition) if ignored_subclass?(owner)
        end

        # @override
        #: (Send send) -> void
        def on_send(send)
          return unless send.recv.nil? && CALLBACKS.include?(send.name)

          arg = send.args.first
          case arg
          when Prism::SymbolNode
            @index.reference_method(arg.unescaped, send.location)
          end

          send.each_arg_assoc do |key, value|
            key = key.slice.delete_suffix(":")

            case key
            when "if", "unless"
              @index.reference_method(value.slice.delete_prefix(":"), send.location) if value
            else
              @index.reference_constant(camelize(key), send.location)
            end
          end
        end
      end
    end
  end
end

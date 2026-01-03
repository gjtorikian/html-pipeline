# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveModel < Base
        ignore_classes_inheriting_from("ActiveModel::EachValidator")
        ignore_methods_named("validate_each", "persisted?")

        # @override
        #: (Send send) -> void
        def on_send(send)
          return if send.recv

          case send.name
          when "attribute", "attributes"
            send.each_arg(Prism::SymbolNode) do |arg|
              @index.reference_method(arg.unescaped, send.location)
            end
          when "validate", "validates", "validates!", "validates_each"
            send.each_arg(Prism::SymbolNode) do |arg|
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
          when "validates_with"
            arg = send.args.first
            if arg.is_a?(Prism::SymbolNode)
              @index.reference_constant(arg.unescaped, send.location)
            end
          end
        end
      end
    end
  end
end

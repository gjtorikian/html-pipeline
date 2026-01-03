# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionMailer < Base
        # @override
        #: (Send send) -> void
        def on_send(send)
          return unless send.recv.nil? && ActionPack::CALLBACKS.include?(send.name)

          send.each_arg(Prism::SymbolNode) do |arg|
            @index.reference_method(arg.unescaped, send.location)
          end
        end
      end
    end
  end
end

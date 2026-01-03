# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Ensures empty class/module definitions in RBI files are
      # done on a single line rather than being split across multiple lines.
      #
      # @example
      #
      #   # bad
      #   module SomeModule
      #   end
      #
      #   # good
      #   module SomeModule; end
      class SingleLineRbiClassModuleDefinitions < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = "Empty class/module definitions in RBI files should be on a single line."

        def on_module(node)
          return if node.body
          return if node.single_line?

          add_offense(node) do |corrector|
            corrector.replace(node, convert_newlines_to_semicolons(node.source))
          end
        end
        alias_method :on_class, :on_module

        private

        def convert_newlines_to_semicolons(source)
          source.sub(/[\r\n]+\s*[\r\n]*/, "; ")
        end
      end
    end
  end
end

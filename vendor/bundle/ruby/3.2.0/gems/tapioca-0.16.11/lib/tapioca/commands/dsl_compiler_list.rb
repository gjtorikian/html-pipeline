# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslCompilerList < AbstractDsl
      private

      sig { override.void }
      def execute
        load_application

        say("")
        say("Loaded DSL compiler classes:")
        say("")

        table = pipeline.compilers.map do |compiler|
          status = if pipeline.active_compilers.include?(compiler)
            set_color("enabled", :green)
          else
            set_color("disabled", :red)
          end

          [compiler.name, status]
        end

        print_table(table, { indent: 2 })
      end
    end
  end
end

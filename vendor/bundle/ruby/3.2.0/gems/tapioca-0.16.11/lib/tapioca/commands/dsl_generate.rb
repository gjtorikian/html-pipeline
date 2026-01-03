# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslGenerate < AbstractDsl
      private

      sig { override.void }
      def execute
        load_application

        say("Compiling DSL RBI files...")
        say("")

        rbi_files_to_purge = generate_dsl_rbi_files(@outpath, quiet: @quiet && !@verbose)
        say("")

        purge_stale_dsl_rbi_files(rbi_files_to_purge)
        say("Done", :green)

        if @auto_strictness && !@lsp_addon
          say("")
          validate_rbi_files(
            command: default_command(:dsl, all_requested_constants.join(" ")),
            gem_dir: @gem_dir,
            dsl_dir: @outpath.to_s,
            auto_strictness: @auto_strictness,
            compilers: pipeline.active_compilers,
          )
        end

        say("All operations performed in working directory.", [:green, :bold])
        say("Please review changes and commit them.", [:green, :bold])
      ensure
        GitAttributes.create_generated_attribute_file(@outpath)
      end
    end
  end
end

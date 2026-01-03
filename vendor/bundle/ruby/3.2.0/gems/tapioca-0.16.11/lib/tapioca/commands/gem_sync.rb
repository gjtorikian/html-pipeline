# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class GemSync < AbstractGem
      private

      sig { override.void }
      def execute
        anything_done = [
          perform_removals,
          perform_additions,
        ].any?

        if anything_done
          validate_rbi_files(
            command: default_command(:gem),
            gem_dir: @outpath.to_s,
            dsl_dir: @dsl_dir,
            auto_strictness: @auto_strictness,
            gems: @bundle.dependencies,
          )

          say("All operations performed in working directory.", [:green, :bold])
          say("Please review changes and commit them.", [:green, :bold])
        else
          say("No operations performed, all RBIs are up-to-date.", [:green, :bold])
        end

        puts
      ensure
        GitAttributes.create_generated_attribute_file(@outpath)
      end
    end
  end
end

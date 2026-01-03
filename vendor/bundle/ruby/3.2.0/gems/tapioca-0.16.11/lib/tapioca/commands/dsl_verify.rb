# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslVerify < AbstractDsl
      private

      sig { override.void }
      def execute
        load_application

        say("Checking for out-of-date RBIs...")
        say("")

        outpath = Pathname.new(Dir.mktmpdir)

        generate_dsl_rbi_files(outpath, quiet: true)
        say("")

        perform_dsl_verification(outpath)
      end
    end
  end
end

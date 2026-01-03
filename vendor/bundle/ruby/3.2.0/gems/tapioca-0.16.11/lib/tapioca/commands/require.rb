# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class Require < CommandWithoutTracker
      sig do
        params(
          requires_path: String,
          sorbet_config_path: String,
        ).void
      end
      def initialize(requires_path:, sorbet_config_path:)
        @requires_path = requires_path
        @sorbet_config_path = sorbet_config_path

        super()
      end

      private

      sig { override.void }
      def execute
        compiler = Static::RequiresCompiler.new(@sorbet_config_path)
        name = set_color(@requires_path, :yellow, :bold)
        say("Compiling #{name}, this may take a few seconds... ")

        rb_string = compiler.compile
        if rb_string.empty?
          say("Nothing to do", :green)
          return
        end

        # Clean all existing requires before regenerating the list so we update
        # it with the new one found in the client code and remove the old ones.
        File.delete(@requires_path) if File.exist?(@requires_path)

        content = +"# typed: true\n"
        content << "# frozen_string_literal: true\n\n"
        content << rb_string

        create_file(@requires_path, content, verbose: false)

        say("Done", :green)

        say("All requires from this application have been written to #{name}.", [:green, :bold])
        cmd = set_color(default_command(:gem), :yellow, :bold)
        say("Please review changes and commit them, then run `#{cmd}`.", [:green, :bold])
      end
    end
  end
end

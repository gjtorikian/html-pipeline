# frozen_string_literal: true

require "pathname"

module RuboCop
  module Cop
    module Sorbet
      # Makes sure that RBI files are always located under the defined allowed paths.
      #
      # Options:
      #
      # * `AllowedPaths`: A list of the paths where RBI files are allowed (default: ["rbi/**", "sorbet/rbi/**"])
      #
      # @example
      #   # bad
      #   # lib/some_file.rbi
      #   # other_file.rbi
      #
      #   # good
      #   # rbi/external_interface.rbi
      #   # sorbet/rbi/some_file.rbi
      #   # sorbet/rbi/any/path/for/file.rbi
      class ForbidRBIOutsideOfAllowedPaths < RuboCop::Cop::Base
        include RangeHelp

        def on_new_investigation
          paths = allowed_paths

          if paths.nil?
            add_global_offense("AllowedPaths expects an array")
            return
          elsif paths.empty?
            add_global_offense("AllowedPaths cannot be empty")
            return
          end

          # When executed the path to the source file is absolute.
          # We need to remove the exec path directory prefix before matching with the filename regular expressions.
          rel_path = processed_source.file_path.sub("#{Dir.pwd}/", "")

          add_global_offense(
            "RBI file path should match one of: #{paths.join(", ")}",
          ) if paths.none? { |pattern| File.fnmatch(pattern, rel_path) }
        end

        private

        def allowed_paths
          paths = cop_config["AllowedPaths"]
          return unless paths.is_a?(Array)

          paths.compact
        end
      end
    end
  end
end

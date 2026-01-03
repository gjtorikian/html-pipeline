# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks that gem versions in RBI annotations are properly formatted per the Bundler gem specification.
      #
      # @example
      #   # bad
      #   # @version > not a version number
      #
      #   # good
      #   # @version = 1
      #
      #   # good
      #   # @version > 1.2.3
      #
      #   # good
      #   # @version <= 4.3-preview
      #
      class ValidGemVersionAnnotations < RuboCop::Cop::Base
        include GemVersionAnnotationHelper

        MSG = "Invalid gem version(s) detected: %<versions>s"
        VALID_OPERATORS = ["=", "!=", ">", ">=", "<", "<=", "~>"]

        def on_new_investigation
          gem_version_annotations.each do |comment|
            gem_versions = gem_versions(comment)

            if gem_versions.empty?
              message = format(MSG, versions: "empty version")
              add_offense(comment, message: message)
              break
            end

            invalid_versions = gem_versions.reject do |version|
              valid_version?(version)
            end

            unless invalid_versions.empty?
              message = format(MSG, versions: invalid_versions.map(&:strip).join(", "))
              add_offense(comment, message: message)
            end
          end
        end

        private

        def valid_version?(version_string)
          parts = version_string.strip.split(" ")
          operator, version = parts

          return false unless operator && parts
          return false unless VALID_OPERATORS.include?(operator)

          Gem::Version.correct?(version)
        end
      end
    end
  end
end

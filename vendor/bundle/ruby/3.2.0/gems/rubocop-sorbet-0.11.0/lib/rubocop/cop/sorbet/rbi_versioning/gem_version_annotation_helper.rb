# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      module GemVersionAnnotationHelper
        VERSION_PREFIX = "# @version"

        def gem_version_annotations
          processed_source.comments.select do |comment|
            gem_version_annotation?(comment)
          end
        end

        private

        def gem_version_annotation?(comment)
          comment.text.start_with?(VERSION_PREFIX)
        end

        def gem_versions(comment)
          comment.text.delete_prefix(VERSION_PREFIX).split(/, ?/).map(&:strip)
        end
      end
    end
  end
end

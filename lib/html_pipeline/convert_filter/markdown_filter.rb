# frozen_string_literal: true

HTMLPipeline.require_dependency("commonmarker", "MarkdownFilter")

class HTMLPipeline
  class ConvertFilter < Filter
    # HTML Filter that converts Markdown text into HTML.
    #
    # Context options:
    #   :markdown[:parse] => Commonmarker parse options
    #   :markdown[:render] => Commonmarker render options
    #   :markdown[:extensions] => Commonmarker extensions options
    class MarkdownFilter < ConvertFilter
      def initialize(context: {}, result: {})
        super
      end

      # Convert Commonmark to HTML using the best available implementation.
      def call(text, context: @context)
        options = context.fetch(:markdown, {})
        plugins = options.fetch(:plugins, {})
        Commonmarker.to_html(text, options: options, plugins: plugins).rstrip!
      end
    end
  end
end

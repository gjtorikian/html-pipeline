# frozen_string_literal: true

HTMLPipeline.require_dependency("commonmarker", "MarkdownFilter")

class HTMLPipeline
  class ConvertFilter
    # HTML Filter that converts Markdown text into HTML.
    #
    # Context options:
    #   :markdown[:parse] => Commonmarker parse options
    #   :markdown[:render] => Commonmarker render options
    #   :markdown[:extensions] => Commonmarker extensions options
    class MarkdownFilter < ConvertFilter
      def initialize(context: {}, result: {})
        super(context: context, result: result)
      end

      # Convert Commonmark to HTML using the best available implementation.
      def call(text)
        options = @context.fetch(:markdown, {})
        Commonmarker.to_html(text, options: options).rstrip!
      end
    end
  end
end

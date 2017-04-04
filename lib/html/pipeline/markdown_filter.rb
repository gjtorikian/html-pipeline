begin
  require "github/markdown"
rescue LoadError => _
  raise HTML::Pipeline::MissingDependencyError, "Missing dependency 'github-markdown' for MarkdownFilter. See README.md for details."
end

module HTML
  class Pipeline
    # HTML Filter that converts Markdown text into HTML and converts into a
    # DocumentFragment. This is different from most filters in that it can take a
    # non-HTML as input. It must be used as the first filter in a pipeline.
    #
    # Context options:
    #   :gfm      => false    Disable GFM line-end processing
    #
    # This filter does not write any additional information to the context hash.
    class MarkdownFilter < TextFilter
      def initialize(text, context = nil, result = nil)
        super text, context, result
        @text = @text.gsub "\r", ''
      end

      # Convert Markdown to HTML using the best available implementation
      # and convert into a DocumentFragment.
      def call
        mode = (context[:gfm] != false) ? :gfm : :markdown
        html = GitHub::Markdown.to_html(@text, mode)
        html.rstrip!
        html
      end
    end
  end
end

require 'github/markdown'

module GitHub::HTML
  # HTML Filter that converts Markdown text into HTML and converts into a
  # DocumentFragment. This is different from most filters in that it can take a
  # non-HTML as input. It must be used as the first filter in a pipeline.
  #
  # Context options:
  #   :gfm      => false    Disable GFM line-end processing
  #   :autolink => false    Disable autolinking URLs
  #
  # This filter does not write any additional information to the context hash.
  class MarkdownFilter < Filter
    def initialize(text, context={})
      raise TypeError, "text cannot be HTML" if text.is_a?(DocumentFragment)
      @text = text.to_s.gsub("\r", '')
      @context = context
      @doc = nil
    end

    # Convert Markdown to HTML using the best available implementation
    # and convert into a DocumentFragment.
    def call
      flags = [:fenced_code, :tables, :strikethrough, :lax_htmlblock, :gh_blockcode, :strict]
      flags << :autolink if context[:autolink] != false
      flags << :hard_wrap if context[:gfm] != false
      html = GitHub::Markdown.new(@text, *flags).to_html
      @doc = parse_html(html)
    end
  end
end

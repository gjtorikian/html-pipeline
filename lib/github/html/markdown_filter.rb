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
      flags = (context[:autolink] == false) ? [] : [:autolink]
      flags << :fenced_code
      html = GitHub::Markdown.new(markdown_text, *flags).to_html
      @doc = parse_html(html)
    end

    # Markdown input text. This includes GFM line-end processing when enabled.
    #
    # Returns the Markdown text as a String
    def markdown_text
      if context[:gfm] != false
        fix_markdown_quirks(@text)
      else
        @text
      end
    end

    # TODO move to GitHub::HTML::ManualWrapFilter or something like that.
    def fix_markdown_quirks(text)
      # Extract pre blocks
      extractions = []
      text.gsub!(%r{^<pre>.*?</pre>}m) do |match|
        extractions << match
        "{gfm-extraction-#{extractions.size}}"
      end

      # in very clear cases, let newlines become <br /> tags
      text.gsub!(/^[\w\<][^\n]*\n+/) do |x|
        x =~ /\n{2}/ ? x : (x.strip!; x << "  \n")
      end

      # Insert pre block extractions
      text.gsub!(/\{gfm-extraction-(\d+)\}/) do
        "\n\n" + extractions.shift
      end

      text
    end
  end
end

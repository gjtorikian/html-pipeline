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
      html =
        if rdiscount?
          flags = (context[:autolink] == false) ? [] : [:autolink]
          Markdown.new(markdown_text, *flags).to_html
        else
          Markdown.new(markdown_text).to_html
        end
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

    # Is RDiscount available and set as the default markdown processor?
    def rdiscount?
      defined?(::RDiscount) && Markdown == RDiscount
    end

    # TODO move to GitHub::HTML::ManualWrapFilter or something like that.
    def fix_markdown_quirks(text)
      # Extract pre blocks
      extractions = []
      text.gsub!(%r{^<pre>.*?</pre>}m) do |match|
        extractions << match
        "{gfm-extraction-#{extractions.size}}"
      end

      # prevent foo_bar_baz from ending up with an italic word in the middle.
      # RDiscount has relaxed emphasis support, so only do this when we're using
      # other markdown implementations.
      if !rdiscount?
        text.gsub!(/(^(?! {4}|\t)\w+_\w+_\w[\w_]*)/) do |x|
          x.gsub('_', '\_') if x.split('').sort.to_s[0..1] == '__'
        end
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

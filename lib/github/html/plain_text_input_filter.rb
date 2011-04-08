module GitHub::HTML
  # Simple filter for plain text input. HTML escapes the text input and wraps it
  # in a div.
  class PlainTextInputFilter < Filter
    def initialize(text, context={})
      raise TypeError, "text cannot be HTML" if text.is_a?(DocumentFragment)
      @text = "<div>#{EscapeUtils.escape_html(text.to_s)}</div>"
      super(@text, context)
    end

    def call
      @doc
    end
  end
end

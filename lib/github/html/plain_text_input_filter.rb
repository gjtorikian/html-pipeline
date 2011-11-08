module GitHub::HTML
  # Simple filter for plain text input. HTML escapes the text input and wraps it
  # in a div.
  class PlainTextInputFilter < Filter
    def initialize(text, context={})
      raise TypeError, "text cannot be HTML" if text.is_a?(DocumentFragment)
      @text = text
      super nil, context
    end

    def call
      "<div>#{EscapeUtils.escape_html(@text.to_s)}</div>"
    end
  end
end

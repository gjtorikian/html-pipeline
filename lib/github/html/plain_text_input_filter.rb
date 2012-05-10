module GitHub::HTML
  # Simple filter for plain text input. HTML escapes the text input and wraps it
  # in a div.
  class PlainTextInputFilter < TextFilter
    def call
      "<div>#{EscapeUtils.escape_html(@text)}</div>"
    end
  end
end

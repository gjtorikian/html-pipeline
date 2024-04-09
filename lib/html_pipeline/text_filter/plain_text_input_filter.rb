# frozen_string_literal: true

class HTMLPipeline
  class TextFilter
    # Simple filter for plain text input. HTML escapes the text input and wraps it
    # in a div.
    class PlainTextInputFilter < TextFilter
      def call(text, context: {}, result: {})
        "<div>#{CGI.escapeHTML(text)}</div>"
      end
    end
  end
end

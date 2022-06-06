# frozen_string_literal: true

HTMLPipeline.require_dependency("escape_utils", "PlainTextInputFilter")

class HTMLPipeline
  class TextFilter
    # Simple filter for plain text input. HTML escapes the text input and wraps it
    # in a div.
    class PlainTextInputFilter < TextFilter
      def call
        "<div>#{EscapeUtils.escape_html(@text, false)}</div>"
      end
    end
  end
end

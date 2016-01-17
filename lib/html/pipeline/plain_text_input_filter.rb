begin
  require "escape_utils"
rescue LoadError => _
  raise HTML::Pipeline::MissingDependencyError, "Missing dependency 'escape_utils' for PlainTextInputFilter. See README.md for details."
end

module HTML
  class Pipeline
    # Simple filter for plain text input. HTML escapes the text input and wraps it
    # in a div.
    class PlainTextInputFilter < TextFilter
      def call
        "<div>#{EscapeUtils.escape_html(@text, false)}</div>"
      end
    end
  end
end

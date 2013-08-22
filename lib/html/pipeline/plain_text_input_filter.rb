begin
  require "escape_utils"
rescue LoadError => e
  missing = HTML::Pipeline::Filter::MissingDependencyException
  raise missing, missing::MESSAGE % "escape_utils", e.backtrace
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

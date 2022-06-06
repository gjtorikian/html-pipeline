# frozen_string_literal: true

class HTMLPipeline
  class NodeFilter < Filter
    def initialize(html, context: {}, result: {})
      typecheck_input(html)
      super(context: context, result: result)
    end

    # Like call but guarantees that a string of HTML markup is returned.
    def self.to_html(input, context: {})
      output = call(input, context: context)
      if output.respond_to?(:to_html)
        output.to_html
      else
        output.to_s
      end
    end

    # The Nokogiri::HTML::DocumentFragment to be manipulated. If the filter was
    # provided a String, parse into a DocumentFragment the first time this
    # method is called.
    def doc
      @doc ||= parse_html(html)
    end

    # The String representation of the document. If a DocumentFragment was
    # provided to the Filter, it is serialized into a String when this method is
    # called.
    def html
      raise InvalidDocumentException if @html.nil? && @doc.nil?

      @html || doc.to_html
    end

    # Ensure the passed argument is a DocumentFragment. When a string is
    # provided, it is parsed and returned; otherwise, the DocumentFragment is
    # returned unmodified.
    private def parse_html(html)
      HTMLPipeline.parse(html)
    end

    private def typecheck_input(doc)
      if doc.is_a?(String)
        @html = doc.to_str
        @doc = nil
      else
        @doc = doc
        @html = nil
      end
    end
  end
end

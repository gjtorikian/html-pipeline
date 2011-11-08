module GitHub::HTML
  # Base class for user content HTML filters. Each filter takes an
  # HTML string or Nokogiri::HTML::DocumentFragment, performs
  # modifications and/or writes information to the context hash. Filters must
  # return a DocumentFragment (typically the same instance provided to the call
  # method) or a String with HTML markup.
  #
  # Example filter that replaces all images with trollface:
  #
  #   class FuuuFilter < GitHub::HTML::Filter
  #     def call
  #       doc.search('img').each do |img|
  #         img['src'] = "http://paradoxdgn.com/junk/avatars/trollface.jpg"
  #       end
  #     end
  #   end
  #
  # The context hash serves dual purposes: it is used to pass options to filters
  # and also to allow filters to make extracted information available to the
  # caller. The hash may be modified in place.
  #
  # Common context options:
  #   :base_url   - The site's base URL
  #   :repository - A Repository providing context for the HTML being processed
  #
  # Each filter may define additional options and output values. See the class
  # docs for more info.
  class Filter
    def initialize(doc, context={})
      if doc.is_a?(String)
        @html = doc
        @doc = nil
      else
        @doc = doc
        @html = nil
      end
      @context = context
    end

    # A simple Hash used to pass extra information into filters and also to
    # allow filters to make extracted information available to the caller.
    attr_reader :context

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
      @html || doc.to_html
    end

    # The main filter entry point. The doc attribute is guaranteed to be a
    # Nokogiri::HTML::DocumentFragment when invoked. Subclasses should modify
    # this document in place or extract information and add it to the context
    # hash.
    def call
      raise NotImplementedError
    end

    # The Repository object provided in the context hash, or nil when no
    # :repository was specified.
    def repository
      context[:repository]
    end

    # The site's base URL provided in the context hash, or '/' when no
    # base URL was specified.
    def base_url
      context[:base_url] || '/'
    end

    # Ensure the passed argument is a DocumentFragment. When a string is
    # provided, it is parsed and returned; otherwise, the DocumentFragment is
    # returned unmodified.
    def parse_html(html)
      GitHub::HTML.parse(html)
    end

    # Perform a filter on doc with the given context.
    #
    # Returns a GitHub::HTML::DocumentFragment or a String containing HTML
    # markup.
    def self.call(doc, context={})
      new(doc, context).call
    end

    # Like call but guarantees that a DocumentFragment is returned, even when
    # the last filter returns a String.
    def self.to_document(input, context={})
      html = call(input, context)
      GitHub::HTML::parse(html)
    end
  end
end

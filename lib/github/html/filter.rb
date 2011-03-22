module GitHub::HTML
  # Base class for user content HTML filters. Each filter takes an
  # HTML string or Nokogiri::HTML::DocumentFragment, performs
  # modifications, or extracts information and makes it available in
  # the context hash.
  #
  # Example filter that replaces all images with trollface:
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
      @doc = parse_html(doc)
      @context = context
    end

    # The Nokogiri::HTML::DocumentFragment to be manipulated.
    attr_reader :doc

    # A simple Hash used to pass extra information into filters and also to
    # allow filters to make extracted information available to the caller.
    attr_reader :context

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
      if html.is_a?(String)
        DocumentFragment.parse(html)
      else
        html
      end
    end

    # Perform a filter on doc with the given context.
    #
    # Returns the modified Nokogiri::HTML::DocumentFragment
    def self.call(doc, context={})
      filter = new(doc, context)
      filter.call
      filter.doc
    end
  end
end

module GitHub::HTML
  # Base class for user content HTML filters.
  class Filter
    def initialize(doc, context={})
      @doc = parse_html(doc)
      @context = context
    end

    attr_reader :doc
    attr_reader :context

    def perform
      raise NotImplementedError
    end

    def repository
      context[:repository]
    end

    def base_url
      context[:base_url] || '/'
    end

    def parse_html(html)
      if html.is_a?(String)
        Nokogiri::HTML::DocumentFragment.parse(html) 
      else
        html
      end
    end

    # Perform a filter on doc with the given context.
    #
    # Returns the modified Nokogiri::HTML::DocumentFragment
    def self.call(doc, context={})
      filter = new(doc, context)
      filter.perform
      filter.doc
    end
  end
end

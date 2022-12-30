# frozen_string_literal: true

class HTMLPipeline
  class NodeFilter
    # HTML Filter for replacing http references to :http_url with https versions.
    # Subdomain references are not rewritten.
    #
    # Context options:
    #   :http_url - The HTTP url to force HTTPS. Falls back to :base_url
    class HttpsFilter < NodeFilter
      SELECTOR = Selma::Selector.new(match_element: %(a[href^="http:"]))

      def selector
        SELECTOR
      end

      def handle_element(element)
        element["href"] = element["href"].sub(/^http:/, "https:")
      end
    end
  end
end

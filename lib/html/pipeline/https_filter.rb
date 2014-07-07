module HTML
  class Pipeline
    # HTML Filter for replacing http references to :base_url with https versions.
    # Subdomain references are not rewritten.
    #
    # Context options:
    #   :base_url - The url to force https
    class HttpsFilter < Filter
      def call
        doc.css(%Q(a[href^="#{context[:base_url]}"])).each do |element|
          element['href'] = element['href'].sub(/^http:/,'https:')
        end
        doc
      end

      # Raise error if :base_url undefined
      def validate
        needs :base_url
      end
    end
  end
end

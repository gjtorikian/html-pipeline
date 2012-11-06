module HTML
  class Pipeline
    # HTML Filter for replacing http github urls with https versions.
    class HttpsFilter < Filter
      def call
        doc.css('a[href^="http://github.com"]').each do |element|
          element['href'] = element['href'].sub(/^http:/,'https:')
        end
        doc
      end
    end
  end
end
require 'uri'

module HTML
  class Pipeline

    class AbsoluteSourceFilter < Filter
      # HTML Filter for replacing relative and root relative image URLs with
      # fully qualified URLs
      #
      # This is useful if an image is root relative but should really be going
      # through a cdn, or if the content for the page assumes the host is known
      # i.e. scraped webpages and some RSS feeds.
      #
      # Context options:
      #   :image_base_url (required) - Base URL for image host for root relative src.
      #   :image_subpage_url (required) - For relative src.
      #
      # This filter does not write additional information to the context.
      # This filter would need to be run before CamoFilter.
      def call
        doc.search("img").each do |element| 
          next if element['src'].nil? || element['src'].empty?
          src = element['src'].strip
          unless src.start_with? 'http'
            if src.start_with? '/'
              base = image_base_url
            else
              base = image_subpage_url
            end
            element["src"] = URI.join(base, src).to_s
          end
        end
        doc
      end
      
      # Implementation of validate hook.
      def validate
        needs :image_base_url, :image_subpage_url
      end
      
      # Private: the base url you want to use
      def image_base_url
        context[:image_base_url]
      end

      # Private: the relative url you want to use
      def image_subpage_url
        context[:image_subpage_url]
      end
    
    end
  end
end
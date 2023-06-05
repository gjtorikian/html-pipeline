# frozen_string_literal: true

require "uri"

class HTMLPipeline
  class NodeFilter
    # HTML Filter for replacing relative and root relative image URLs with
    # fully qualified URLs
    #
    # This is useful if an image is root relative but should really be going
    # through a cdn, or if the content for the page assumes the host is known
    # i.e. scraped webpages and some RSS feeds.
    #
    # Context options:
    #   :image_base_url - Base URL for image host for root relative src.
    #   :image_subpage_url - For relative src.
    #
    # This filter does not write additional information to the context.
    # Note: This filter would need to be run before AssetProxyFilter.
    class AbsoluteSourceFilter < NodeFilter
      SELECTOR = Selma::Selector.new(match_element: "img")

      def selector
        SELECTOR
      end

      def handle_element(element)
        src = element["src"]
        return if src.nil? || src.empty?

        src = src.strip
        return if src.start_with?("http")

        base = if src.start_with?("/")
          image_base_url
        else
          image_subpage_url
        end

        element["src"] = URI.join(base, src).to_s
      end

      # Private: the base url you want to use
      def image_base_url
        context[:image_base_url] || raise("Missing context :image_base_url for #{self.class.name}")
      end

      # Private: the relative url you want to use
      def image_subpage_url
        context[:image_subpage_url] || raise("Missing context :image_subpage_url for #{self.class.name}")
      end
    end
  end
end

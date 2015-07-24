require 'uri'
require 'net/http'

module HTML
  class Pipeline
    class FlickrFilter < TextFilter
      def call
        regex = %r{https?://(www\.)?flickr\.com/photos/[^\s<]*}
        uri = URI("https://www.flickr.com/services/oembed")

        link_attr = context[:flickr_link_attr] || ""

        @text.gsub(regex) do |match|
          params = {
            url: match,
            format: :json,
            maxwidth: max_value(:width),
            maxheight: max_value(:height)
          }

          uri.query = URI.encode_www_form(params)

          response = JSON.parse(Net::HTTP.get(uri))

          %{<a href="#{match}" #{link_attr}><img src="#{response["url"]}" alt="#{response["title"]}" title="#{response["title"]}" /></a>}
        end
      end

      private

      def max_value(attr)
        value = context["flickr_max#{attr}".to_sym]
        value.to_i >= 0 ? value.to_i : 0
      end
    end
  end
end

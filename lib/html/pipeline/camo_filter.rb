require 'openssl'

module HTML
  class Pipeline
    # HTML Filter for replacing http image URLs with camo versions. See:
    #
    # https://github.com/atmos/camo
    #
    # All images provided in user content should be run through this
    # filter so that http image sources do not cause mixed-content warnings
    # in browser clients.
    #
    # Context options:
    #   :asset_proxy (required) - Base URL for constructed asset proxy URLs.
    #   :asset_proxy_secret_key (required) - The shared secret used to encode URLs.
    #
    # This filter does not write additional information to the context.
    class CamoFilter < Filter
      # Hijacks images in the markup provided, replacing them with URLs that
      # go through the github asset proxy.
      def call
        doc.search("img").each do |element|
          next if element['src'].nil?
          src = element['src'].strip
          src = src.sub(%r!^http://github.com!, 'https://github.com')
          next if context[:disable_asset_proxy]

          if src =~ /^http:/ || src =~ /^https:\/\/img.skitch.com\//
            element['src'] = asset_proxy_url(src)
          else
            element['src'] = src
          end
        end
        doc
      end
      
      # Implementation of validate hook.
      # Errors should raise exceptions or use an existing validator.
      def validate
        needs :asset_proxy, :asset_proxy_secret_key
      end

      # The camouflaged URL for a given image URL.
      def asset_proxy_url(url)
        "#{asset_proxy_host}/#{asset_url_hash(url)}/#{hexencode(url)}"
      end

      # Private: calculate the HMAC digest for a image source URL.
      def asset_url_hash(url)
        digest = OpenSSL::Digest::Digest.new('sha1')
        OpenSSL::HMAC.hexdigest(digest, asset_proxy_secret_key, url)
      end

      # Private: the hostname to use for generated asset proxied URLs.
      def asset_proxy_host
        context[:asset_proxy]
      end

      def asset_proxy_secret_key
        context[:asset_proxy_secret_key]
      end

      # Private: helper to hexencode a string. Each byte ends up encoded into
      # two characters, zero padded value in the range [0-9a-f].
      def hexencode(str)
        str.to_enum(:each_byte).map { |byte| "%02x" % byte }.join
      end
    end
  end
end
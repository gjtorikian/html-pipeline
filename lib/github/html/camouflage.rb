module GitHub::HTML
  # Mixin with methods for dealing with the camo SSL image proxy:
  #
  # https://github.com/github/camo
  #
  # All images provided in user content should be run through the asset_hijack
  # filter so that http image sources do not cause mixed-content warning in
  # browser clients.
  module Camouflage
    # Hijacks images in the markup provided, replacing them with URLs that
    # go through the github asset proxy.
    #
    # doc - String with HTML markup or a Nokogiri document/fragment.
    #
    # Returns the asset hijacked markup as a nokogiri document fragment.
    def asset_hijack(doc)
      raise ArgumentError, "doc cannot be nil" if doc.nil?
      doc = Nokogiri::HTML::DocumentFragment.parse(doc) if doc.is_a?(String)

      doc.search("img").each do |element|
        src = element['src']
        next if src =~ /^#{GitHub::SSLHost}/ || src !~ /^http:/
        element['src'] = asset_proxy_url_for(src)
      end
      doc
    end

    # The camouflaged URL for a given image URL.
    def asset_proxy_url_for(url)
      "#{asset_proxy_host}/#{asset_url_hash(url)}/#{hexencode(url)}"
    end

    # Private: calculate the HMAC digest for a image source URL.
    def asset_url_hash(url)
      digest = OpenSSL::Digest::Digest.new('sha1')
      OpenSSL::HMAC.hexdigest(digest, GitHub::AssetProxySecretKey, url)
    end

    # Private: the hostname to use for generated asset proxied URLs.
    def asset_proxy_host
      GitHub::AssetProxyHostName % rand(3)
    end

    # Private: helper to hexencode a string. Each byte ends up encoded into
    # two characters, zero padded value in the range [0-9a-f].
    def hexencode(str)
      str.to_enum(:each_byte).map { |byte| "%02x" % byte }.join
    end

    extend self
  end
end

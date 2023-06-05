# frozen_string_literal: true

require "openssl"

class HTMLPipeline
  class NodeFilter
    # Proxy images/assets to another server, such as
    # [cactus/go-camo](https://github.com/cactus/go-camo#).
    # Reduces mixed content warnings as well as hiding the customer's
    # IP address when requesting images.
    # Copies the original img `src` to `data-canonical-src` then replaces the
    # `src` with a new url to the proxy server.
    #
    # Based on https://github.com/gjtorikian/html-pipeline/blob/v2.14.3/lib/html/pipeline/camo_filter.rb
    class AssetProxyFilter < NodeFilter
      SELECTOR = Selma::Selector.new(match_element: "img")

      def selector
        SELECTOR
      end

      def handle_element(element)
        original_src = element["src"]
        return unless original_src

        begin
          uri = URI.parse(original_src)
        rescue StandardError
          return
        end

        return if uri.host.nil? && !original_src.start_with?("///")
        return if asset_host_allowed?(uri.host)

        element["src"] = asset_proxy_url(original_src)
        element["data-canonical-src"] = original_src
      end

      def validate
        needs(:asset_proxy, :asset_proxy_secret_key)
      end

      def asset_host_allowed?(host)
        context[:asset_proxy_domain_regexp] ? context[:asset_proxy_domain_regexp].match?(host) : false
      end

      class << self
        # This helps setup the context. It's not needed if you're always providing
        # all the necessary keys in the context. One example would be to override
        # this and pull the settings from a set of global application settings.
        def transform_context(context, proxy_settings = {})
          context[:asset_proxy] = proxy_settings[:url] if proxy_settings[:url]
          context[:asset_proxy_secret_key] = proxy_settings[:secret_key] if proxy_settings[:secret_key]

          allowlist = determine_allowlist(proxy_settings)
          context[:asset_proxy_domain_regexp] ||= compile_allowlist(allowlist)

          context
        end

        def compile_allowlist(domain_list)
          return if domain_list.empty?

          escaped = domain_list.map { |domain| Regexp.escape(domain).gsub("\\*", ".*?") }
          Regexp.new("^(#{escaped.join("|")})$", Regexp::IGNORECASE)
        end

        def determine_allowlist(proxy_settings)
          proxy_settings[:allowlist] || []
        end
      end

      private def asset_proxy_url(url)
        "#{context[:asset_proxy]}/#{asset_url_hash(url)}/#{hexencode(url)}"
      end

      private def asset_url_hash(url)
        OpenSSL::HMAC.hexdigest("sha1", context[:asset_proxy_secret_key], url)
      end

      private def hexencode(str)
        str.unpack1("H*")
      end
    end
  end
end

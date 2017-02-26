require "digest"
require "cgi"

module HTML
  class Pipeline
    class GravatarFilter < AvatarFilter
      class InvalidGravatarServiceError < StandardError; end

      USERNAME_TOKEN = "__username_token__".freeze
      RATING = "g".freeze
      SIZE = "40".freeze

      def validate
        super

        unless service.respond_to? :username_to_email
          raise InvalidGravatarServiceError,
            "GravatarFilter avatar service must implement `username_to_email'"
        end
      end

      def username_token
        context[:gravatar_username_token] || USERNAME_TOKEN
      end

      def rating
        context[:gravatar_rating] || RATING
      end

      def size
        context[:gravatar_size] || SIZE
      end

      def default
        context[:gravatar_default_image] || nil
      end

      def width
        size
      end

      def height
        size
      end

      def avatar_image_link_filter(text)
        return text unless text.include?(delimiter)

        text.gsub pattern do |match|
          username = $1
          gravatar = gravatar_from_username(username)
          image_link_to_profile(username, gravatar, base_url)
        end
      end

      def gravatar_from_username(username)
        "https://www.gravatar.com/avatar/#{hash(username)}?#{params(username)}"
      end

      def hash(username)
        email = service.username_to_email(username)
        Digest::MD5.hexdigest(email)
      end

      def params(username)
        params = "s=#{size}&r=#{rating}"
        params << "&d=#{CGI.escape(default_image(username))}" if default
        params
      end

      def default_image(username)
        default.sub(USERNAME_TOKEN, username) if default
      end
    end
  end
end

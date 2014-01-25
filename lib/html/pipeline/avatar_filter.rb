module HTML
  class Pipeline
    class AvatarFilter < Filter

      DELIMITER = "$".freeze

      # Don't look for avatars in text nodes that are children of these elements
      IGNORE_PARENTS = %w(pre code a).to_set

      # Username may only contain alphanumeric characters
      # or dashes and cannot begin with a dash
      AvatarPattern = /
        #{Regexp.escape(DELIMITER)} # Delimiter, overridable in context
        ((?>[a-z0-9][a-z0-9-]*))    # username, borrowed from MentionPattern
        #{Regexp.escape(DELIMITER)} # Delimiter, overridable in context
      /ix.freeze

      def call
        doc.search('text()').each do |node|
          content = node.to_html
          next if !content.include?(delimiter)
          next if has_ancestor?(node, IGNORE_PARENTS)
          html = avatar_image_link_filter(content)
          next if html == content
          node.replace(html)
        end
        doc
      end

      def avatar_image_link_filter(text)
        raise NotImplementedError, "#{self.class} cannot respond to: #{__method__}"
      end

      def validate
        needs :avatar_service
      end

      def service
        context[:avatar_service]
      end

      def pattern
        context[:avatar_pattern] || AvatarPattern
      end

      def delimiter
        context[:avatar_delimiter] || DELIMITER
      end

      def width
        context[:avatar_width] || nil
      end

      def height
        context[:avatar_height] || nil
      end

      def image_link_to_profile(username, avatar, base_url="/")
        url = File.join(base_url, username)
        "<a href='#{url}' class='user-avatar'>" +
        "<img title='#{username}' alt='#{username}' src='#{avatar}' width='#{width}' height='#{height}'>" +
        "</a>"
      end
    end
  end
end

require 'emoji'

module HTML::Pipeline
  # HTML filter that replaces :emoji: with images.
  #
  # Context:
  #   :asset_root - base url to link to emoji sprite
  class EmojiFilter < Filter
    # Build a regexp that matches all valid :emoji: names.
    EmojiPattern = /:(#{Emoji.names.map { |name| Regexp.escape(name) }.join('|')}):/

    def call
      doc.search('text()').each do |node|
        content = node.to_html
        next if !content.include?(':')
        next if has_ancestor?(node, %w(pre code))
        html = emoji_image_filter(content)
        next if html == content
        node.replace(html)
      end
      doc
    end

    # Replace :emoji: with corresponding images.
    #
    # text - String text to replace :emoji: in.
    #
    # Returns a String with :emoji: replaced with images.
    def emoji_image_filter(text)
      return text unless text.include?(':')

      text.gsub EmojiPattern do |match|
        name = $1
        "<img class='emoji' title=':#{name}:' alt=':#{name}:' src='#{File.join(asset_root, "emoji", "#{name}.png")}' height='20' width='20' align='absmiddle' />"
      end
    end

    # The base url to link emoji sprites
    #
    # Raises ArgumentError if context option has not been provided.
    # Returns the context's asset_root.
    def asset_root
      context[:asset_root] or raise ArgumentError, "Missing context :asset_root"
    end
  end
end

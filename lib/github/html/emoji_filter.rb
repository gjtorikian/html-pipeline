module GitHub::HTML
  # HTML filter that replaces :emoji: with images.
  class EmojiFilter < Filter
    # List of supported emoji as name => code pairs.
    #
    # To add emoji:
    #   - add entries from http://emoji.rubyforge.org/#emoji_table
    #   - run GitHub::HTML::EmojiFilter.generate_assets
    Emoji = {
      # Campfire emoji
      'sunny' => 'e04a',
      'zap' => 'e13d',
      'leaves' => 'e447',
      'lipstick' => 'e31c',
      'cop' => 'e152',
      'wheelchair' => 'e20a',
      'fish' => 'e522',
      'hammer' => 'e116',
      'moneybag' => 'e12f',
      'calling' => 'e104',
      'memo' => 'e301',
      'mega' => 'e317',
      'gift' => 'e112',
      'pencil' => 'e301',
      'scissors' => 'e313',
      'feet' => 'e536',
      'runner' => 'e115',
      'heart' => 'e022',
      'smoking' => 'e30e',
      'warning' => 'e252',
      'ok' => 'e24d',
      'tm' => 'e537',
      'vs' => 'e12e',
      'new' => 'e212',
      'bulb' => 'e10f',
      'zzz' => 'e13c',
      'sparkles' => 'e32e',
      'star' => 'e32f',
      'mag' => 'e114',
      'lock' => 'e144',
      'email' => 'e103',
      'fist' => 'e010',
      'v' => 'e011',
      'punch' => 'e00d',
      '+1' => 'e00e',
      'clap' => 'e41f',
      '-1' => 'e421',

      # More emoji
      'fire' => 'e11d',
      'cake' => 'e046',
      'iphone' => 'e00a',
      'computer' => 'e00c',
      'book' => 'e148',
      'ski' => 'e013',
      'airplane' => 'e01d',
      'bus' => 'e159',
      'train' => 'e01e',
      'bike' => 'e136',
      'taxi' => 'e15a',
      'tophat' => 'e503',
      'art' => 'e502',
      'cool' => 'e214',
      'bomb' => 'e311',
      'key' => 'e03f',
      'bear' => 'e051',
      'beer' => 'e047',
      'thumbsup' => 'e00e',

      # Custom emoji
      'octocat' => nil
    }

    # Build a regexp that matches all valid :emoji: names.
    EmojiPattern = /:(#{Emoji.map{ |name,code| Regexp.escape(name) }.join('|')}):/

    def call
      doc.search('text()').each do |node|
        content = node.to_html
        next if !content.include?(':')
        next if node.ancestors('pre, code, a').any?
        html = self.class.emoji_image_filter(content)
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
    def self.emoji_image_filter(text)
      return text unless text.include?(':')

      text.gsub EmojiPattern do |match|
        name = $1
        "<img class='emoji' title=':#{name}:' alt=':#{name}:' src='#{GitHub::AssetHost}/images/icons/emoji/v2/#{name}.png' height='20' width='20' align='absmiddle' />"
      end
    end

    # Regenerate css/gif assets for all entries in Emoji.
    #
    # dir - a String path to the emoji-css-builder source
    #
    # If the directory provided does not exist, emoji-css-builder will
    # be checked out there. You will probably still need to install
    # ghostscript and other dependencies manually.
    #
    # Returns nothing.
    def self.regenerate_assets(dir = '~/Dropbox/GitHub/stock/Emoji/')
      require 'fileutils'
      dir = File.expand_path(dir)

      if !File.exists?(dir)
        raise 'Could not find emoji source'
      end

      Emoji.each do |name, code|
        next unless code
        file = File.join(dir, "kb-emoji-U+#{code.upcase}@2x.png")

        raise "Unknown emoji: #{name}" unless File.exists?(file)
        FileUtils.cp file, RAILS_ROOT+"/public/images/icons/emoji/#{name}.png"
      end
    end
  end
end

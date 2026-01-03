require 'gemojione/version'
require 'json'

# Optionally load EscapeUtils if it's available
begin
  require 'escape_utils'
rescue LoadError
  require 'cgi'
end

require 'gemojione/index'
require 'gemojione/categories'
# require 'gemojione/index_importer'

require 'gemojione/railtie' if defined?(Rails::Railtie)

module Gemojione
  @asset_host = nil
  @asset_path = nil
  @default_size = nil
  @use_svg = false
  @use_sprite = false

  @escaper = defined?(EscapeUtils) ? EscapeUtils : CGI

  def self.asset_host
    @asset_host || 'http://localhost:3000'
  end

  def self.asset_host=(host)
    @asset_host = host
  end

  def self.asset_path
    @asset_path || '/'
  end

  def self.asset_path=(path)
    @asset_path = path
  end

  def self.default_size
    @default_size
  end

  def self.default_size=(size)
    @default_size = size
  end

  def self.use_svg
    @use_svg
  end

  def self.use_svg=(useit)
    @use_svg = useit
  end

  def self.use_sprite
    @use_sprite
  end

  def self.use_sprite=(useit)
    @use_sprite = useit
  end

  def self.image_url_for_name(name)
    emoji = index.find_by_name(name)
    unicode = use_svg ? emoji['unicode'].upcase : emoji['unicode'].downcase
    "#{asset_host}#{ File.join(asset_path, unicode) }.#{ use_svg ? 'svg' : 'png' }"
  end

  def self.image_url_for_unicode_moji(moji)
    emoji = index.find_by_moji(moji)
    image_url_for_name(emoji['name'])
  end

  def self.image_tag_for_moji(moji)
    emoji = index.find_by_moji(moji)
    if use_sprite
      %Q{<span class="emojione emojione-#{emoji['unicode'].to_s.downcase}" alt="#{ emoji['name'] }" title="#{ emoji['shortname'] }">#{ moji }</span>}
    else
      %Q{<img alt="#{emoji['moji']}" class="emoji" src="#{ image_url_for_unicode_moji(moji) }"#{ default_size ? ' style="width: '+default_size+';"' : '' }>}
    end
  end

  def self.image_tag_for_unicode(unicode)
    emoji = index.find_by_unicode(unicode)
    if use_sprite
      %Q{<span class="emojione emojione-#{emoji['unicode'].to_s.downcase}" alt="#{ emoji['name'] }" title="#{ emoji['shortname'] }">#{ emoji['moji'] }</span>}
    else
      %Q{<img alt="#{emoji['name']}" class="emoji" src="#{ image_url_for_unicode_moji(emoji['moji']) }"#{ default_size ? ' style="width: '+default_size+';"' : '' }>}
    end
  end

  def self.replace_unicode_moji_with_images(string)
    return string unless string
    unless string.match(index.unicode_moji_regex)
      return safe_string(string)
    end

    safe_string = safe_string(string.dup)
    safe_string.gsub!(index.unicode_moji_regex) do |moji|
      Gemojione.image_tag_for_moji(moji)
    end
    safe_string = safe_string.html_safe if safe_string.respond_to?(:html_safe)

    safe_string
  end

  def self.replace_named_moji_with_images(string)
    return string unless string
    unless string.match(index.shortname_moji_regex)
      return safe_string(string)
    end

    safe_string = safe_string(string.dup)
    safe_string.gsub!(index.shortname_moji_regex) do |code|
      name = code.tr(':','')
      moji = index.find_by_name(name)
      Gemojione.image_tag_for_unicode(moji['unicode'])
    end
    safe_string = safe_string.html_safe if safe_string.respond_to?(:html_safe)

    safe_string
  end

  def self.replace_named_moji_with_unicode_moji(string)
    return string unless string
    unless string.match(index.shortname_moji_regex)
      return safe_string(string)
    end

    safe_string = safe_string(string.dup)
    safe_string.gsub!(index.shortname_moji_regex) do |code|
      name = code.tr(':','')
      moji = index.find_by_name(name)
      moji['moji']
    end

    safe_string = safe_string.html_safe if safe_string.respond_to?(:html_safe)

    safe_string
  end

  def self.replace_ascii_moji_with_images(string)
    return string unless string
    unless string.match(index.ascii_moji_regex)
      return safe_string(string)
    end

    string.gsub!(index.ascii_moji_regex) do |code|
      moji = index.find_by_ascii(code)['moji']
      Gemojione.image_tag_for_moji(moji)
    end

    unless string.respond_to?(:html_safe?) && string.html_safe?
      safe_string = CGI::unescapeElement(CGI.escape_html(string), %w[span img])
    end
    safe_string = safe_string.html_safe if safe_string.respond_to?(:html_safe)

    safe_string
  end

  def self.replace_unicode_moji_with_names(string)
    return string unless string
    unless string.match(index.unicode_moji_regex)
      return safe_string(string)
    end

      safe_string = safe_string(string.dup)
      safe_string.gsub!(index.unicode_moji_regex) do |moji|
        index.find_by_moji(moji)['shortname']
      end
      safe_string = safe_string.html_safe if safe_string.respond_to?(:html_safe)

      safe_string
  end

  def self.safe_string(string)
    if string.respond_to?(:html_safe?) && string.html_safe?
      string
    else
      escape_html(string)
    end
  end

  def self.escape_html(string)
    @escaper.escape_html(string)
  end

  def self.index
    @index ||= Index.new
  end

  def self.images_path
    File.expand_path("../assets/#{ use_svg ? 'svg' : 'png' }", File.dirname(__FILE__))
  end

  def self.sprites_path
    File.expand_path("../assets/sprites", File.dirname(__FILE__))
  end
end

class String
  def with_emoji_images
    Gemojione.replace_unicode_moji_with_images(self)
  end

  def with_emoji_names
    Gemojione.replace_named_moji_with_images(self)
  end

  def image_url
    Gemojione.image_url_for_name(self.emoji_data['name'])
  end

  def emoji_data
    index = Gemojione.index
    index.find_by_moji(self) || index.find_by_name(self)
  end
end

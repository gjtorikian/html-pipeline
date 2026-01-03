# encoding: UTF-8

require 'gemojione/string_ext'

describe String, 'with Emoji extensions' do
  describe '#with_emoji_images' do
    it 'should replace unicode moji with an img tag' do
      base_string = "I ❤ Emoji"
      replaced_string = base_string.with_emoji_images
      assert_equal "I <img alt=\"❤\" class=\"emoji\" src=\"http://localhost:3000/2764.png\"> Emoji", replaced_string
    end
  end

  describe '#with_emoji_names' do
    it 'should replace named moji with an img tag' do
      base_string = "I :heart: Emoji"
      replaced_string = base_string.with_emoji_names
      assert_equal "I <img alt=\"heart\" class=\"emoji\" src=\"http://localhost:3000/2764.png\"> Emoji", replaced_string
    end
  end

  describe '#image_url' do
    it 'should generate image_url' do
      assert_equal 'http://localhost:3000/1f300.png', '🌀'.image_url
      assert_equal 'http://localhost:3000/1f300.png', 'cyclone'.image_url
    end
  end

  describe '#emoji_data' do
    it 'should find data for a name or a moji' do
      data_from_moji = '❤'.emoji_data
      data_from_string = 'heart'.emoji_data

      assert_equal data_from_moji, data_from_string
    end
  end
end

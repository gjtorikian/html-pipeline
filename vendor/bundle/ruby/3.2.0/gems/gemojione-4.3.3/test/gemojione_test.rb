# encoding: UTF-8

require File.absolute_path File.dirname(__FILE__) + '/test_helper'

describe Gemojione do
  describe "image_url_for_name" do
    it 'should generate url' do
      assert_equal 'http://localhost:3000/1f300.png', Gemojione.image_url_for_name('cyclone')
    end

    it 'should generate url' do
      assert_equal 'http://localhost:3000/1f44d.png', Gemojione.image_url_for_name('+1')
    end

    it 'should generate url' do
      with_emoji_config(:use_svg, true) do
        assert_equal 'http://localhost:3000/1F44D.svg', Gemojione.image_url_for_name('+1')
      end
    end
  end

  describe "image_url_for_unicode_moji" do
    it 'should generate url' do
      assert_equal 'http://localhost:3000/1f300.png', Gemojione.image_url_for_unicode_moji('🌀')
    end
  end

  describe "asset_host" do
    it 'should default to localhost' do
      assert_equal 'http://localhost:3000', Gemojione.asset_host
    end

    it 'should be configurable' do
      with_emoji_config(:asset_host, 'emoji') do
        assert_equal 'emoji', Gemojione.asset_host
      end
    end
  end

  describe "asset_path" do
    it 'should default to /' do
      assert_equal '/', Gemojione.asset_path
    end

    it 'should be configurable' do
      with_emoji_config(:asset_path, '/emoji') do
        assert_equal '/emoji', Gemojione.asset_path
      end
    end
  end

  describe 'default size' do
    it 'should default to nil' do
      assert_equal nil, Gemojione.default_size
    end

    it 'should be configurable' do
      with_emoji_config(:default_size, '32px') do
        assert_equal '32px', Gemojione.default_size
      end
    end
  end

  describe 'image_tag_for_moji' do
    it 'should generate a clean img tag if default_size undefined' do
      assert_equal '<img alt="🌀" class="emoji" src="http://localhost:3000/1f300.png">', Gemojione.image_tag_for_moji('🌀')
    end

    it 'should generate a img tag with style tag if default_size is defined' do
      Gemojione.default_size='42px'
      assert_equal '<img alt="🌀" class="emoji" src="http://localhost:3000/1f300.png" style="width: 42px;">', Gemojione.image_tag_for_moji('🌀')
      Gemojione.default_size=nil
    end

    it 'should generate spritesheet tag' do
      with_emoji_config(:use_sprite, true) do
        assert_equal "<span class=\"emojione emojione-1f300\" alt=\"cyclone\" title=\":cyclone:\">🌀</span>", Gemojione.image_tag_for_moji('🌀')
      end
    end
  end

  describe "replace_unicode_moji_with_images" do
    it 'should return original string without emoji' do
      assert_equal "foo", Gemojione.replace_unicode_moji_with_images('foo')
    end

    it 'should escape html in non html_safe aware strings' do
      replaced_string = Gemojione.replace_unicode_moji_with_images('❤<script>')
      assert_equal "<img alt=\"❤\" class=\"emoji\" src=\"http://localhost:3000/2764.png\">&lt;script&gt;", replaced_string
    end

    it 'should replace unicode moji with img tag' do
      base_string = "I ❤ Emoji"
      replaced_string = Gemojione.replace_unicode_moji_with_images(base_string)
      assert_equal "I <img alt=\"❤\" class=\"emoji\" src=\"http://localhost:3000/2764.png\"> Emoji", replaced_string
    end

    it 'should replace diversity unicode moji properly' do
      base_string = "Woman elf tone5 🧝🏿‍♀️"
      replaced_string = Gemojione.replace_unicode_moji_with_images(base_string)
      assert_equal "Woman elf tone5 <img alt=\"🧝🏿‍♀️\" class=\"emoji\" src=\"http://localhost:3000/1f9dd-1f3ff-2640.png\">", replaced_string
    end

    it 'should replace unicode moji with span tag for spritesheet' do
      with_emoji_config(:use_sprite, true) do
        base_string = "I ❤ Emoji"
        replaced_string = Gemojione.replace_unicode_moji_with_images(base_string)
        assert_equal "I <span class=\"emojione emojione-2764\" alt=\"heart\" title=\":heart:\">❤</span> Emoji", replaced_string
      end
    end

    it 'should escape regex breaker mojis' do
      assert_equal "<img alt=\"*⃣\" class=\"emoji\" src=\"http://localhost:3000/002a-20e3.png\">", Gemojione.replace_unicode_moji_with_images('*⃣')
    end

    it 'should handle nil string' do
      assert_equal nil, Gemojione.replace_unicode_moji_with_images(nil)
    end

    describe 'with html_safe buffer' do
      it 'should escape non html_safe? strings in emoji' do
        string = HtmlSafeString.new('❤<script>')

        replaced_string = string.stub(:html_safe?, false) do
          Gemojione.replace_unicode_moji_with_images(string)
        end

        assert_equal "<img alt=\"❤\" class=\"emoji\" src=\"http://localhost:3000/2764.png\">&lt;script&gt;", replaced_string
      end

      it 'should escape non html_safe? strings in all strings' do
        string = HtmlSafeString.new('XSS<script>')

        replaced_string = string.stub(:html_safe?, false) do
          Gemojione.replace_unicode_moji_with_images(string)
        end

        assert_equal "XSS&lt;script&gt;", replaced_string
      end

      it 'should not escape html_safe strings' do
        string = HtmlSafeString.new('❤<a href="harmless">')

        replaced_string = string.stub(:html_safe?, true) do
          Gemojione.replace_unicode_moji_with_images(string)
        end

        assert_equal "<img alt=\"❤\" class=\"emoji\" src=\"http://localhost:3000/2764.png\"><a href=\"harmless\">", replaced_string
      end

      it 'should always return an html_safe string for emoji' do
        string = HtmlSafeString.new('❤')
        replaced_string = string.stub(:html_safe, 'safe_buffer') do
           Gemojione.replace_unicode_moji_with_images(string)
        end

        assert_equal "safe_buffer", replaced_string
      end

      it 'should always return an html_safe string for any string' do
        string = HtmlSafeString.new('Content')
        replaced_string = string.stub(:html_safe, 'safe_buffer') do
           Gemojione.replace_unicode_moji_with_images(string)
        end

        assert_equal "Content", replaced_string
      end
    end
  end

  describe 'replace_named_moji_with_images' do
    it 'should replace with span tag for spritesheet' do
      with_emoji_config(:use_sprite, true) do
        base_string = "I :heart: Emoji"
        replaced_string = Gemojione.replace_named_moji_with_images(base_string)
        assert_equal "I <span class=\"emojione emojione-2764\" alt=\"heart\" title=\":heart:\">❤</span> Emoji", replaced_string
      end
    end

    it 'should return original string without emoji' do
      assert_equal 'foo', Gemojione.replace_named_moji_with_images('foo')
    end

    it 'should escape html in non html_safe aware strings' do
      replaced_string = Gemojione.replace_named_moji_with_images(':heart:<script>')
      assert_equal "<img alt=\"heart\" class=\"emoji\" src=\"http://localhost:3000/2764.png\">&lt;script&gt;", replaced_string
    end

    it 'should replace coded moji with img tag' do
      base_string = "I :heart: Emoji"
      replaced_string = Gemojione.replace_named_moji_with_images(base_string)
      assert_equal "I <img alt=\"heart\" class=\"emoji\" src=\"http://localhost:3000/2764.png\"> Emoji", replaced_string
    end

    it 'should replace aliased moji with img tag' do
      base_string = "Good one :+1:"
      replaced_string = Gemojione.replace_named_moji_with_images(base_string)
      assert_equal "Good one <img alt=\"thumbsup\" class=\"emoji\" src=\"http://localhost:3000/1f44d.png\">", replaced_string
    end

    it 'should handle nil string' do
      assert_equal nil, Gemojione.replace_named_moji_with_images(nil)
    end

    describe 'with html_safe buffer' do
      it 'should escape non html_safe? strings in emoji' do
        string = HtmlSafeString.new(':heart:<script>')

        replaced_string = string.stub(:html_safe?, false) do
          Gemojione.replace_named_moji_with_images(string)
        end

        assert_equal "<img alt=\"heart\" class=\"emoji\" src=\"http://localhost:3000/2764.png\">&lt;script&gt;", replaced_string
      end

      it 'should escape non html_safe? strings in all strings' do
        string = HtmlSafeString.new('XSS<script>')

        replaced_string = string.stub(:html_safe?, false) do
          Gemojione.replace_named_moji_with_images(string)
        end

        assert_equal "XSS&lt;script&gt;", replaced_string
      end

      it 'should not escape html_safe strings' do
        string = HtmlSafeString.new(':heart:<a href="harmless">')

        replaced_string = string.stub(:html_safe?, true) do
          Gemojione.replace_named_moji_with_images(string)
        end

        assert_equal "<img alt=\"heart\" class=\"emoji\" src=\"http://localhost:3000/2764.png\"><a href=\"harmless\">", replaced_string
      end

      it 'should always return an html_safe string for emoji' do
        string = HtmlSafeString.new(':heart:')
        replaced_string = string.stub(:html_safe, 'safe_buffer') do
          Gemojione.replace_named_moji_with_images(string)
        end

        assert_equal "safe_buffer", replaced_string
      end

      it 'should always return an html_safe string for any string' do
        string = HtmlSafeString.new('Content')
        replaced_string = string.stub(:html_safe, 'safe_buffer') do
          Gemojione.replace_named_moji_with_images(string)
        end

        assert_equal "Content", replaced_string
      end

      it 'should escape non html_safe? strings with ascii' do
        string = HtmlSafeString.new('Moji is <3 XSS<script> attacks are not')

        replaced_string = string.stub(:html_safe?, false) do
          Gemojione.replace_ascii_moji_with_images(string)
        end

        assert_equal "Moji is <img alt=\"❤\" class=\"emoji\" src=\"http://localhost:3000/2764.png\"> XSS&lt;script&gt; attacks are not", replaced_string
      end
    end
  end

  describe 'replace_named_moji_with_unicode_moji' do
    it 'should replace emoji name with unicode moji' do
      replaced_string = Gemojione.replace_named_moji_with_unicode_moji("Going for a walk! :woman_walking:")
      assert_equal "Going for a walk! 🚶‍♀️", replaced_string
    end
  end

  describe "replace_ascii_moji_with_images" do
    it 'should replace ascii moji with img tag' do
      replaced_string = Gemojione.replace_ascii_moji_with_images("Emoji is :-)")
      assert_equal "Emoji is <img alt=\"😄\" class=\"emoji\" src=\"http://localhost:3000/1f604.png\">", replaced_string
    end

    it 'should replace ascii moji with span tag for sprite' do
      with_emoji_config(:use_sprite, true) do
        replaced_string = Gemojione.replace_ascii_moji_with_images("Emoji is :-)")
        assert_equal "Emoji is <span class=\"emojione emojione-1f604\" alt=\"smile\" title=\":smile:\">😄</span>", replaced_string
      end
    end
  end

  describe "replace_unicode_moji_with_names" do
    it 'should replace unicode mojis with their shortnames' do
      replaced_string = Gemojione.replace_unicode_moji_with_names("Emoji is 😄")
      assert_equal "Emoji is :smile:", replaced_string
    end

    it 'replaces diversity mojis with their shortnames properly' do
      replaced_string = Gemojione.replace_unicode_moji_with_names("Emoji is 🧝🏿‍♀️")
      assert_equal "Emoji is :woman_elf_tone5:", replaced_string
    end
  end

  describe "images_path" do
    it "should always return a valid default path" do
      path = Gemojione.images_path

      assert Dir.exist?(path)
      assert_equal "png", path.split('/').last
    end

    it "should always return a valid svg path" do

      with_emoji_config(:use_svg, true) do
        path = Gemojione.images_path

        assert Dir.exist?(path)
        assert_equal "svg", path.split('/').last
      end
    end
  end

  describe "sprites_path" do
    it "should return sprite stylesheet" do
      assert File.exist?("#{Gemojione.sprites_path}/emojione.sprites.scss")
    end

    it "should return PNG sprites" do
      assert File.exist?("#{Gemojione.sprites_path}/emojione.sprites.png")
    end
  end

  class HtmlSafeString < String
    def initialize(*); super; end
    def html_safe; self; end
    def html_safe?; true; end
    def dup; self; end
  end

  def with_emoji_config(name, value)
    original_value = Gemojione.send(name)
    begin
      Gemojione.send("#{name}=", value)
      yield
    ensure
      Gemojione.send("#{name}=", original_value)
    end
  end
end

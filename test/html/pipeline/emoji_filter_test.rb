require 'test_helper'

class HTML::Pipeline::EmojiFilterTest < Test::Unit::TestCase
  def test_emojify
    filter = HTML::Pipeline::EmojiFilter.new("<p>:shipit:</p>", {:asset_root => 'https://foo.com'})
    doc = filter.call
    assert_match "https://foo.com/emoji/shipit.png", doc.search('img').attr('src').value
  end

  def test_missing_context
    filter = HTML::Pipeline::EmojiFilter.new("<p>:shipit:</p>", {})
    assert_raises ArgumentError do
      filter.call
    end
  end
end
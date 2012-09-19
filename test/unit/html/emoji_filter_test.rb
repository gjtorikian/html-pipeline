require 'test_helper'

class GitHub::HTML::EmojiFilterTest < Test::Unit::TestCase
  def test_emojify
    filter = GitHub::HTML::EmojiFilter.new("<p>:shipit:</p>", {:asset_root => 'https://foo.com'})
    doc = filter.call
    assert_match "https://foo.com/emoji/shipit.png", doc.search('img').attr('src').value
  end
end
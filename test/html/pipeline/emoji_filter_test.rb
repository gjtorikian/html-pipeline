require 'test_helper'

class HTML::Pipeline::EmojiFilterTest < Test::Unit::TestCase
  EmojiFilter = HTML::Pipeline::EmojiFilter
  
  def test_emojify
    filter = EmojiFilter.new("<p>:shipit:</p>", {:asset_root => 'https://foo.com'})
    doc = filter.call
    assert_match "https://foo.com/emoji/shipit.png", doc.search('img').attr('src').value
  end
  
  def test_uri_encoding
    filter = EmojiFilter.new("<p>:+1:</p>", {:asset_root => 'https://foo.com'})
    doc = filter.call
    assert_match "https://foo.com/emoji/%2B1.png", doc.search('img').attr('src').value
  end
  
  def test_required_context_validation
    exception = assert_raise(ArgumentError) { 
      EmojiFilter.call("", {}) 
    }
    assert_match /:asset_root/, exception.message
  end
end

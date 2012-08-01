require 'test_helper'

class GitHub::HTML::EmojiFilterTest < Test::Unit::TestCase
  def test_emojify
    filter = GitHub::HTML::EmojiFilter.new("<p>:shipit:</p>")
    doc = filter.call
    assert_match %r{emoji/shipit.png}, doc.to_html
  end
end
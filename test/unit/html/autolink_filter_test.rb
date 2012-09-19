require "test_helper"

AutolinkFilter = GitHub::HTML::AutolinkFilter

class GitHub::HTML::AutolinkFilterTest < Test::Unit::TestCase
  def test_uses_rinku_for_autolinking
    # just try to parse a complicated piece of HTML
    # that Rails auto_link cannot handle
    assert_equal '<p>"<a href="http://www.github.com">http://www.github.com</a>"</p>',
      AutolinkFilter.to_html('<p>"http://www.github.com"</p>')
  end
end

require "test_helper"

AutolinkFilter = HTML::Pipeline::AutolinkFilter

class HTML::Pipeline::AutolinkFilterTest < Test::Unit::TestCase
  def test_uses_rinku_for_autolinking
    # just try to parse a complicated piece of HTML
    # that Rails auto_link cannot handle
    assert_equal '<p>"<a href="http://www.github.com">http://www.github.com</a>"</p>',
      AutolinkFilter.to_html('<p>"http://www.github.com"</p>')
  end

  def test_autolink_option
    assert_equal '<p>"http://www.github.com"</p>',
      AutolinkFilter.to_html('<p>"http://www.github.com"</p>', :autolink => false)
  end

  def test_autolink_flags
    assert_equal '<p>"<a href="http://github">http://github</a>"</p>',
      AutolinkFilter.to_html('<p>"http://github"</p>', :flags => Rinku::AUTOLINK_SHORT_DOMAINS)
  end
end

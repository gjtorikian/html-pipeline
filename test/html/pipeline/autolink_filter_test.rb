# frozen_string_literal: true

require 'test_helper'

AutolinkFilter = HTML::Pipeline::AutolinkFilter

class HTML::Pipeline::AutolinkFilterTest < Minitest::Test
  def test_uses_rinku_for_autolinking
    # just try to parse a complicated piece of HTML
    # that Rails auto_link cannot handle
    assert_equal '<p>"<a href="http://www.github.com">http://www.github.com</a>"</p>',
                 AutolinkFilter.to_html('<p>"http://www.github.com"</p>')
  end

  def test_autolink_option
    assert_equal '<p>"http://www.github.com"</p>',
                 AutolinkFilter.to_html('<p>"http://www.github.com"</p>', context: { autolink: false })
  end

  def test_autolink_link_attr
    assert_equal '<p>"<a href="http://www.github.com" target="_blank">http://www.github.com</a>"</p>',
                 AutolinkFilter.to_html('<p>"http://www.github.com"</p>', context: { link_attr: 'target="_blank"' })
  end

  def test_autolink_flags
    assert_equal '<p>"<a href="http://github">http://github</a>"</p>',
                 AutolinkFilter.to_html('<p>"http://github"</p>', context: { flags: Rinku::AUTOLINK_SHORT_DOMAINS })
  end

  def test_autolink_skip_tags
    assert_equal '<code>"http://github.com"</code>',
                 AutolinkFilter.to_html('<code>"http://github.com"</code>')

    assert_equal '<code>"<a href="http://github.com">http://github.com</a>"</code>',
                 AutolinkFilter.to_html('<code>"http://github.com"</code>', context: { skip_tags: %w[kbd script] })
  end

  def test_link_mode_default
    assert_equal '<p>"<a href="http://www.github.com">http://www.github.com</a>"</p><p>"user@example.com"</p>',
                 AutolinkFilter.to_html('<p>"http://www.github.com"</p><p>"user@example.com"</p>')
  end

  def test_link_mode_urls
    assert_equal '<p>"<a href="http://www.github.com">http://www.github.com</a>"</p><p>"user@example.com"</p>',
                 AutolinkFilter.to_html('<p>"http://www.github.com"</p><p>"user@example.com"</p>', context: { link_mode: :urls })
  end

  def test_link_mode_all
    assert_equal '<p>"<a href="http://www.github.com">http://www.github.com</a>"</p><p>"<a href="mailto:user@example.com">user@example.com</a>"</p>',
                 AutolinkFilter.to_html('<p>"http://www.github.com"</p><p>"user@example.com"</p>', context: { link_mode: :all })
  end

  def test_link_mode_email_addresses
    assert_equal '<p>"http://www.github.com"</p><p>"<a href="mailto:user@example.com">user@example.com</a>"</p>',
                 AutolinkFilter.to_html('<p>"http://www.github.com"</p><p>"user@example.com"</p>', context: { link_mode: :email_addresses })
  end
end

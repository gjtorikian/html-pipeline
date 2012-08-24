require File.expand_path('../../../test_helper', __FILE__)

AutolinkFilter = GitHub::HTML::AutolinkFilter

context "GitHub::HTML::AutolinkFilter" do
  test "uses Rinku for autolinking" do
    # just try to parse a complicated piece of HTML
    # that Rails auto_link cannot handle
    assert_equal '<p>"<a href="http://www.github.com">http://www.github.com</a>"</p>',
      AutolinkFilter.to_html('<p>"http://www.github.com"</p>')
  end
end

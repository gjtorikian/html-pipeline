require File.expand_path('../../../test_helper', __FILE__)

context "GitHub::HTML::ImageMaxWidthFilter" do
  def filter(html)
    GitHub::HTML::ImageMaxWidthFilter.call(html)
  end

  test "rewrites image style tags" do
    body = "<p>Screenshot: <img src='screenshot.png'></p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = filter(doc)
    assert_equal_html %q(<p>Screenshot: <a target="_blank" href="screenshot.png"><img src="screenshot.png" style="max-width:100%;"></a></p>),
      res.to_html
  end

  test "leaves existing image style tags alone" do
    body = "<p><img src='screenshot.png' style='width:100px;'></p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = filter(doc)
    assert_equal_html '<p><img src="screenshot.png" style="width:100px;"></p>',
      res.to_html
  end

  test "links to image" do
    body = "<p>Screenshot: <img src='screenshot.png'></p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = filter(doc)
    assert_equal_html '<p>Screenshot: <a target="_blank" href="screenshot.png"><img src="screenshot.png" style="max-width:100%;"></a></p>',
      res.to_html
  end

  test "doesnt link to image when already linked" do
    body = "<p>Screenshot: <a href='blah.png'><img src='screenshot.png'></a></p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = filter(doc)
    assert_equal_html %q(<p>Screenshot: <a href="blah.png"><img src="screenshot.png" style="max-width:100%;"></a></p>),
      res.to_html
  end

  test "doesn't screw up inlined images" do
    body = "<p>Screenshot <img src='screenshot.png'>, yes, this is a <b>screenshot</b> indeed.</p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    assert_equal_html %q(<p>Screenshot <a target="_blank" href="screenshot.png"><img src="screenshot.png" style="max-width:100%;"></a>, yes, this is a <b>screenshot</b> indeed.</p>), filter(doc).to_html
  end
end

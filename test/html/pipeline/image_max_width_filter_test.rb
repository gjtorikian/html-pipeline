require "test_helper"

class HTML::Pipeline::ImageMaxWidthFilterTest < Minitest::Test
  def filter(html)
    HTML::Pipeline::ImageMaxWidthFilter.call(html)
  end

  def test_rewrites_image_style_tags
    body = "<p>Screenshot: <img src='screenshot.png'></p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = filter(doc)
    assert_equal_html %q(<p>Screenshot: <a target="_blank" href="screenshot.png"><img src="screenshot.png" style="max-width:100%;"></a></p>),
      res.to_html
  end

  def test_leaves_existing_image_style_tags_alone
    body = "<p><img src='screenshot.png' style='width:100px;'></p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = filter(doc)
    assert_equal_html '<p><img src="screenshot.png" style="width:100px;"></p>',
      res.to_html
  end

  def test_links_to_image
    body = "<p>Screenshot: <img src='screenshot.png'></p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = filter(doc)
    assert_equal_html '<p>Screenshot: <a target="_blank" href="screenshot.png"><img src="screenshot.png" style="max-width:100%;"></a></p>',
      res.to_html
  end

  def test_doesnt_link_to_image_when_already_linked
    body = "<p>Screenshot: <a href='blah.png'><img src='screenshot.png'></a></p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = filter(doc)
    assert_equal_html %q(<p>Screenshot: <a href="blah.png"><img src="screenshot.png" style="max-width:100%;"></a></p>),
      res.to_html
  end

  def test_doesnt_screw_up_inlined_images
    body = "<p>Screenshot <img src='screenshot.png'>, yes, this is a <b>screenshot</b> indeed.</p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    assert_equal_html %q(<p>Screenshot <a target="_blank" href="screenshot.png"><img src="screenshot.png" style="max-width:100%;"></a>, yes, this is a <b>screenshot</b> indeed.</p>), filter(doc).to_html
  end
end

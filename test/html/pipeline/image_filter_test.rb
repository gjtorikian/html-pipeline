require "test_helper"

ImageFilter = HTML::Pipeline::ImageFilter

class HTML::Pipeline::ImageFilterTest < Minitest::Test
  def filter(html)
    ImageFilter.to_html(html)
  end

  def test_jpg
    assert_equal %(<img src="http://example.com/test.jpg" alt=""/>),
    filter(%(http://example.com/test.jpg))
  end

  def test_jpeg
    assert_equal %(<img src="http://example.com/test.jpeg" alt=""/>),
    filter(%(http://example.com/test.jpeg))
  end

  def test_bmp
    assert_equal %(<img src="http://example.com/test.bmp" alt=""/>),
    filter(%(http://example.com/test.bmp))
  end

  def test_gif
    assert_equal %(<img src="http://example.com/test.gif" alt=""/>),
    filter(%(http://example.com/test.gif))
  end

  def test_png
    assert_equal %(<img src="http://example.com/test.png" alt=""/>),
    filter(%(http://example.com/test.png))
  end

  def test_https_url
    assert_equal %(<img src="https://example.com/test.png" alt=""/>),
    filter(%(https://example.com/test.png))
  end
end

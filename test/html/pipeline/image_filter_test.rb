# frozen_string_literal: true

require 'test_helper'

ImageFilter = HTML::Pipeline::ImageFilter

class HTML::Pipeline::ImageFilterTest < Minitest::Test
  def setup
    @filter = ImageFilter
  end

  def test_jpg
    assert_equal %(<img src="http://example.com/test.jpg" alt=""/>),
                 @filter.to_html(%(http://example.com/test.jpg))
  end

  def test_jpeg
    assert_equal %(<img src="http://example.com/test.jpeg" alt=""/>),
                 @filter.to_html(%(http://example.com/test.jpeg))
  end

  def test_bmp
    assert_equal %(<img src="http://example.com/test.bmp" alt=""/>),
                 @filter.to_html(%(http://example.com/test.bmp))
  end

  def test_gif
    assert_equal %(<img src="http://example.com/test.gif" alt=""/>),
                 @filter.to_html(%(http://example.com/test.gif))
  end

  def test_png
    assert_equal %(<img src="http://example.com/test.png" alt=""/>),
                 @filter.to_html(%(http://example.com/test.png))
  end

  def test_https_url
    assert_equal %(<img src="https://example.com/test.png" alt=""/>),
                 @filter.to_html(%(https://example.com/test.png))
  end
end

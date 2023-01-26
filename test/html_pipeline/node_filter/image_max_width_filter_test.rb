# frozen_string_literal: true

require "test_helper"

class HTMLPipeline
  class ImageMaxWidthFilterTest < Minitest::Test
    def setup
      @filter = HTMLPipeline::NodeFilter::ImageMaxWidthFilter
    end

    def test_rewrites_image_style_tags
      body = '<p>Screenshot: <img src="screenshot.png"></p>'
      res = @filter.call(body)

      assert_equal(
        '<p>Screenshot: <a target="_blank" href="screenshot.png"><img src="screenshot.png" style="max-width:100%;"></a></p>',
        res,
      )
    end

    def test_leaves_existing_image_style_tags_alone
      body = '<p><img src="screenshot.png" style="width:100px;"></p>'

      res = @filter.call(body)

      assert_equal(
        '<p><img src="screenshot.png" style="width:100px;"></p>',
        res,
      )
    end

    def test_links_to_image
      body = '<p>Screenshot: <img src="screenshot.png"></p>'

      res = @filter.call(body)

      assert_equal(
        '<p>Screenshot: <a target="_blank" href="screenshot.png"><img src="screenshot.png" style="max-width:100%;"></a></p>',
        res,
      )
    end

    def test_doesnt_link_to_image_when_already_linked
      body = '<p>Screenshot: <a href="blah.png"><img src="screenshot.png"></a></p>'

      res = @filter.call(body)

      assert_equal(
        '<p>Screenshot: <a href="blah.png"><img src="screenshot.png" style="max-width:100%;"></a></p>',
        res,
      )
    end

    def test_doesnt_screw_up_inlined_images
      body = '<p>Screenshot <img src="screenshot.png">, yes, this is a <b>screenshot</b> indeed.</p>'

      res = @filter.call(body)

      assert_equal('<p>Screenshot <a target="_blank" href="screenshot.png"><img src="screenshot.png" style="max-width:100%;"></a>, yes, this is a <b>screenshot</b> indeed.</p>', res)
    end
  end
end

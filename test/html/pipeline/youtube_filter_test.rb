require "test_helper"

YoutubeFilter = HTML::Pipeline::YoutubeFilter

class HTML::Pipeline::YoutubeFilterTest < Minitest::Test
  def test_transform_with_default_value
    assert_equal %(<div class="video youtube"><iframe width="420" height="315" src="//www.youtube.com/embed/Kg4aWWIsszw" frameborder="0" allowfullscreen></iframe></div>),
    YoutubeFilter.to_html(%(https://www.youtube.com/watch?v=Kg4aWWIsszw))
  end

  def test_transform_with_custom_context_value
    assert_equal %(<div class="video youtube"><iframe width="500" height="100" src="//www.youtube.com/embed/Kg4aWWIsszw?autoplay=1&rel=0" frameborder="5" allowfullscreen></iframe></div>),
    YoutubeFilter.to_html(%(https://www.youtube.com/watch?v=Kg4aWWIsszw), video_width: 500, video_height: 100, video_frameborder: 5, video_autoplay: true, video_hide_related: true)
  end
end

require "test_helper"

FlickrFilter = HTML::Pipeline::FlickrFilter

class HTML::Pipeline::FlickrFilterTest < Minitest::Test

  def test_with_default_option
    assert_equal %(<a href="https://www.flickr.com/photos/99434203@N05/9379906996" ><img src="https://farm4.staticflickr.com/3787/9379906996_3ccabd5aae_b.jpg" alt="Ebony&Alex-011-IMGP4840" title="Ebony&Alex-011-IMGP4840" /></a>),
    FlickrFilter.to_html(%(https://www.flickr.com/photos/99434203@N05/9379906996))
  end

  def test_with_maxwidth_and_maxheight
    assert_equal %(<a href="https://www.flickr.com/photos/99434203@N05/9379906996" ><img src="https://farm4.staticflickr.com/3787/9379906996_3ccabd5aae_t.jpg" alt="Ebony&Alex-011-IMGP4840" title="Ebony&Alex-011-IMGP4840" /></a>),
    FlickrFilter.to_html(%(https://www.flickr.com/photos/99434203@N05/9379906996), flickr_maxwidth: 100, flickr_maxheight: 200)
  end

  def test_with_link_attr
    assert_equal %(<a href="https://www.flickr.com/photos/99434203@N05/9379906996" target='_blank'><img src="https://farm4.staticflickr.com/3787/9379906996_3ccabd5aae_b.jpg" alt="Ebony&Alex-011-IMGP4840" title="Ebony&Alex-011-IMGP4840" /></a>),
    FlickrFilter.to_html(%(https://www.flickr.com/photos/99434203@N05/9379906996), flickr_link_attr: "target='_blank'")
  end
end

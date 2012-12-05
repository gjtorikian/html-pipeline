require "test_helper"

class HTML::Pipeline::AbsoluteSourceFilterTest < Test::Unit::TestCase
  AbsoluteSourceFilter = HTML::Pipeline::AbsoluteSourceFilter

  def setup
    @image_base_url = 'http://assets.example.com'
    @image_subpage_url = 'http://blog.example.com/a/post'
    @options = {
      :image_base_url    => @image_base_url,
      :image_subpage_url => @image_subpage_url
    }
  end

  def test_rewrites_root_relative_urls
    orig = %(<p><img src="/img.png"></p>)
    assert_equal "<p><img src=\"#{@image_base_url}/img.png\"></p>",
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_rewrites_relative_urls
    orig = %(<p><img src="post/img.png"></p>)
    assert_equal "<p><img src=\"#{@image_subpage_url}/img.png\"></p>",
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_does_not_rewrite_absolute_urls
    orig = %(<p><img src="http://other.example.com/img.png"></p>)
    result = AbsoluteSourceFilter.call(orig, @options).to_s
    assert_no_match /@image_base_url/, result
    assert_no_match /@image_subpage_url/, result
  end
  
  def test_required_context_validation
    exception = assert_raise(ArgumentError) { 
      AbsoluteSourceFilter.call("", {}) 
    }
    assert_match /:image_base_url/, exception.message
    assert_match /:image_subpage_url/, exception.message
  end
end

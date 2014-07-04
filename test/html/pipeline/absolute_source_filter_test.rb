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

  def test_rewrites_root_urls
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

  def test_fails_when_context_is_missing
    assert_raise RuntimeError do
      AbsoluteSourceFilter.call("<img src=\"img.png\">", {})
    end
    assert_raise RuntimeError do
      AbsoluteSourceFilter.call("<img src=\"/img.png\">", {})
    end
  end
  
  def test_tells_you_where_context_is_required
    exception = assert_raise(RuntimeError) { 
      AbsoluteSourceFilter.call("<img src=\"img.png\">", {}) 
    }
    assert_match 'HTML::Pipeline::AbsoluteSourceFilter', exception.message

    exception = assert_raise(RuntimeError) { 
      AbsoluteSourceFilter.call("<img src=\"/img.png\">", {}) 
    }
    assert_match 'HTML::Pipeline::AbsoluteSourceFilter', exception.message
  end

end

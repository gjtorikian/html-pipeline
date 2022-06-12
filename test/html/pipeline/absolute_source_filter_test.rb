# frozen_string_literal: true

require 'test_helper'

class HTML::Pipeline::AbsoluteSourceFilterTest < Minitest::Test
  AbsoluteSourceFilter = HTML::Pipeline::AbsoluteSourceFilter

  def setup
    @image_base_url = 'http://assets.example.com'
    @image_subpage_url = 'http://blog.example.com/a/post'
    @options = {
      image_base_url: @image_base_url,
      image_subpage_url: @image_subpage_url
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
    refute_match /@image_base_url/, result
    refute_match /@image_subpage_url/, result
  end

  def test_fails_when_context_is_missing
    assert_raises RuntimeError do
      AbsoluteSourceFilter.call('<img src="img.png">', {})
    end
    assert_raises RuntimeError do
      AbsoluteSourceFilter.call('<img src="/img.png">', {})
    end
  end

  def test_tells_you_where_context_is_required
    exception = assert_raises(RuntimeError) do
      AbsoluteSourceFilter.call('<img src="img.png">', {})
    end
    assert_match 'HTML::Pipeline::AbsoluteSourceFilter', exception.message

    exception = assert_raises(RuntimeError) do
      AbsoluteSourceFilter.call('<img src="/img.png">', {})
    end
    assert_match 'HTML::Pipeline::AbsoluteSourceFilter', exception.message
  end

  def test_ignores_data_urls
    orig = %(<p><img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 696 391'%3E%3Crect x='0' y='0' width='696' height='391' fill='%23f2f2f2'%3E%3C/rect%3E%3C/svg%3E"></p>)
    result = AbsoluteSourceFilter.call(orig, @options).to_s

    expected = %(<p><img src="data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%20696%20391'%3E%3Crect%20x='0'%20y='0'%20width='696'%20height='391'%20fill='%23f2f2f2'%3E%3C/rect%3E%3C/svg%3E"></p>)
    assert_equal expected, result
  end
end

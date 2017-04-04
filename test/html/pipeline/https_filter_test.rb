require "test_helper"

HttpsFilter = HTML::Pipeline::HttpsFilter

class HTML::Pipeline::AutolinkFilterTest < Minitest::Test
  def filter(html)
    HttpsFilter.to_html(html, @options)
  end

  def setup
    @options = {:base_url => "http://github.com"}
  end

  def test_http
    assert_equal %(<a href="https://github.com">github.com</a>),
          filter(%(<a href="http://github.com">github.com</a>))
  end

  def test_https
    assert_equal %(<a href="https://github.com">github.com</a>),
          filter(%(<a href="https://github.com">github.com</a>))
  end

  def test_subdomain
    assert_equal %(<a href="http://help.github.com">github.com</a>),
          filter(%(<a href="http://help.github.com">github.com</a>))
  end

  def test_other
    assert_equal %(<a href="http://github.io">github.io</a>),
          filter(%(<a href="http://github.io">github.io</a>))
  end

  def test_uses_http_url_over_base_url
    @options =  {:http_url => "http://github.com", :base_url => "https://github.com"}

    assert_equal %(<a href="https://github.com">github.com</a>),
          filter(%(<a href="http://github.com">github.com</a>))
  end

  def test_only_http_url
    @options = {:http_url => "http://github.com"}

    assert_equal %(<a href="https://github.com">github.com</a>),
          filter(%(<a href="http://github.com">github.com</a>))
  end

  def test_validates_http_url
    @options.clear
    exception = assert_raises(ArgumentError) { filter("") }
    assert_match "HTML::Pipeline::HttpsFilter: :http_url", exception.message
  end
end

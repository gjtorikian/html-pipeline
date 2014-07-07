require "test_helper"

HttpsFilter = HTML::Pipeline::HttpsFilter

class HTML::Pipeline::AutolinkFilterTest < Minitest::Test
  def filter(html, base_url="http://github.com")
    HttpsFilter.to_html(html, :base_url => base_url)
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

  def test_validation
    exception = assert_raises(ArgumentError) { HttpsFilter.call(nil, {}) }
    assert_match "HTML::Pipeline::HttpsFilter: :base_url", exception.message
  end
end

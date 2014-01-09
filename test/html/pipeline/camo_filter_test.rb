require "test_helper"

class HTML::Pipeline::CamoFilterTest < Test::Unit::TestCase
  CamoFilter = HTML::Pipeline::CamoFilter

  def setup
    @asset_proxy_url        = 'https//assets.example.org'
    @asset_proxy_secret_key = 'ssssh-secret'
    @options = {
      :asset_proxy            => @asset_proxy_url,
      :asset_proxy_secret_key => @asset_proxy_secret_key
    }
  end

  def test_camouflaging_http_image_urls
    orig = %(<p><img src="http://twitter.com/img.png"></p>)
    assert_includes 'img src="' + @asset_proxy_url,
      CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_dotcom_image_urls
    orig = %(<p><img src="https://github.com/img.png"></p>)
    assert_equal "<p><img src=\"https://github.com/img.png\"></p>",
      CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_dotcom_subdomain_image_urls
    orig = %(<p><img src="https://raw.github.com/img.png"></p>)
    assert_equal "<p><img src=\"https://raw.github.com/img.png\"></p>",
      CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_dotcom_app_image_urls
    orig = %(<p><img src="https://githubapp.com/img.png"></p>)
    assert_equal "<p><img src=\"https://githubapp.com/img.png\"></p>",
      CamoFilter.call(orig, @options).to_s
  end

  def test_camouflaging_https_image_urls
    orig = %(<p><img src="https://foo.com/img.png"></p>)
    assert_includes 'img src="' + @asset_proxy_url,
      CamoFilter.call(orig, @options).to_s
  end

  def test_handling_images_with_no_src_attribute
    orig = %(<p><img></p>)
    assert_nothing_raised do
      CamoFilter.call(orig, @options).to_s
    end
  end

  def test_required_context_validation
    exception = assert_raise(ArgumentError) {
      CamoFilter.call("", {})
    }
    assert_match /:asset_proxy[^_]/, exception.message
    assert_match /:asset_proxy_secret_key/, exception.message
  end
end

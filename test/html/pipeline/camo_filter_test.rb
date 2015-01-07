require "test_helper"

class HTML::Pipeline::CamoFilterTest < Minitest::Test
  CamoFilter = HTML::Pipeline::CamoFilter

  def setup
    @asset_proxy_url        = 'https//assets.example.org'
    @asset_proxy_secret_key = 'ssssh-secret'
    @options = {
      :asset_proxy            => @asset_proxy_url,
      :asset_proxy_secret_key => @asset_proxy_secret_key,
      :asset_proxy_whitelist  => [/(^|\.)github\.com$/]
    }
  end

  def test_asset_proxy_disabled
    orig = %(<p><img src="http://twitter.com/img.png"></p>)
    assert_equal orig,
      CamoFilter.call(orig, @options.merge(:disable_asset_proxy => true)).to_s
  end

  def test_camouflaging_http_image_urls
    orig = %(<p><img src="http://twitter.com/img.png"></p>)
    assert_equal %(<p><img src="https//assets.example.org/a5ad43494e343b20d745586282be61ff530e6fa0/687474703a2f2f747769747465722e636f6d2f696d672e706e67" data-canonical-src="http://twitter.com/img.png"></p>),
      CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_dotcom_image_urls
    orig = %(<p><img src="https://github.com/img.png"></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_dotcom_subdomain_image_urls
    orig = %(<p><img src="https://raw.github.com/img.png"></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_dotcom_subsubdomain_image_urls
    orig = %(<p><img src="https://f.assets.github.com/img.png"></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_camouflaging_github_prefixed_image_urls
    orig = %(<p><img src="https://notgithub.com/img.png"></p>)
    assert_equal %(<p><img src="https//assets.example.org/5d4a96c69713f850520538e04cb9661035cfb534/68747470733a2f2f6e6f746769746875622e636f6d2f696d672e706e67" data-canonical-src="https://notgithub.com/img.png"></p>),
      CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_absolute_image_urls
    orig = %(<p><img src="/img.png"></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_relative_image_urls
    orig = %(<p><img src="img.png"></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_camouflaging_https_image_urls
    orig = %(<p><img src="https://foo.com/img.png"></p>)
    assert_equal %(<p><img src="https//assets.example.org/3c5c6dc74fd6592d2596209dfcb8b7e5461383c8/68747470733a2f2f666f6f2e636f6d2f696d672e706e67" data-canonical-src="https://foo.com/img.png"></p>),
      CamoFilter.call(orig, @options).to_s
  end

  def test_handling_images_with_no_src_attribute
    orig = %(<p><img></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_required_context_validation
    exception = assert_raises(ArgumentError) {
      CamoFilter.call("", {})
    }
    assert_match /:asset_proxy[^_]/, exception.message
    assert_match /:asset_proxy_secret_key/, exception.message
  end
end

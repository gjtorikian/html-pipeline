require File.expand_path('../../../test_helper', __FILE__)

context "GitHub::HTML::CamoFilter" do
  CamoFilter = GitHub::HTML::CamoFilter

  fixtures do
    @asset_proxy_url = 'https//assets.example.org'
  end

  test "camouflaging http image urls" do
    orig = %(<p><img src="http://twitter.com/img.png"></p>)
    assert_includes 'img src="' + @asset_proxy_url,
      CamoFilter.call(orig, :asset_proxy => @asset_proxy_url).to_s
  end

  test "rewrites http://github.com image urls" do
    orig = %(<p><img src="http://github.com/img.png"></p>)
    assert_equal "<p><img src=\"https://github.com/img.png\"></p>",
      CamoFilter.call(orig, :asset_proxy => @asset_proxy_url).to_s
  end

  test "not camouflaging https image urls" do
    orig = %(<p><img src="https://foo.com/img.png"></p>)
    assert_doesnt_include 'img src="' + @asset_proxy_url,
      CamoFilter.call(orig, :asset_proxy => @asset_proxy_url).to_s
  end

  test "handling images with no src attribute" do
    orig = %(<p><img></p>)
    assert_nothing_raised do
      CamoFilter.call(orig, :asset_proxy => @asset_proxy_url).to_s
    end
  end
end

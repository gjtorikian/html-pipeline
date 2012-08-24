require File.expand_path('../../../test_helper', __FILE__)

context "GitHub::HTML::SanitizationFilter" do
  SanitizationFilter = GitHub::HTML::SanitizationFilter

  test "removing script tags" do
    orig = %(<p><img src="http://github.com/img.png" /><script></script></p>)
    html = SanitizationFilter.call(orig).to_s
    assert_no_match /script/, html
  end

  test "removing style tags" do
    orig = %(<p><style>hey now</style></p>)
    html = SanitizationFilter.call(orig).to_s
    assert_no_match /style/, html
  end

  test "removing style attributes" do
    orig = %(<p style='font-size:1000%'>YO DAWG</p>)
    html = SanitizationFilter.call(orig).to_s
    assert_no_match /font-size/, html
    assert_no_match /style/, html
  end

  test "removing script event handler attributes" do
    orig = %(<a onclick='javascript:alert(0)'>YO DAWG</a>)
    html = SanitizationFilter.call(orig).to_s
    assert_no_match /javscript/, html
    assert_no_match /onclick/, html
  end

  test "sanitizes LI elements not contained in UL or OL" do
    stuff = "a\n<li>b</li>\nc"
    html  = SanitizationFilter.call(stuff).to_s
    assert_equal "a\n b \nc", html
  end

  test "does not sanitize LI elements contained in UL or OL" do
    stuff = "a\n<ul><li>b</li></ul>\nc"
    assert_equal stuff, SanitizationFilter.call(stuff).to_s
  end

  test "github-specific protocols are not removed" do
    stuff = '<a href="github-windows://spillthelog">Spill this yo</a> and so on'
    assert_equal stuff, SanitizationFilter.call(stuff).to_s
  end
end

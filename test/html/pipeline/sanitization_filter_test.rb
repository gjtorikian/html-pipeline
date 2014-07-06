require "test_helper"

class HTML::Pipeline::SanitizationFilterTest < Minitest::Test
  SanitizationFilter = HTML::Pipeline::SanitizationFilter

  def test_removing_script_tags
    orig = %(<p><img src="http://github.com/img.png" /><script></script></p>)
    html = SanitizationFilter.call(orig).to_s
    refute_match /script/, html
  end

  def test_removing_style_tags
    orig = %(<p><style>hey now</style></p>)
    html = SanitizationFilter.call(orig).to_s
    refute_match /style/, html
  end

  def test_removing_style_attributes
    orig = %(<p style='font-size:1000%'>YO DAWG</p>)
    html = SanitizationFilter.call(orig).to_s
    refute_match /font-size/, html
    refute_match /style/, html
  end

  def test_removing_script_event_handler_attributes
    orig = %(<a onclick='javascript:alert(0)'>YO DAWG</a>)
    html = SanitizationFilter.call(orig).to_s
    refute_match /javscript/, html
    refute_match /onclick/, html
  end

  def test_sanitizes_li_elements_not_contained_in_ul_or_ol
    stuff = "a\n<li>b</li>\nc"
    html  = SanitizationFilter.call(stuff).to_s
    assert_equal "a\nb\nc", html
  end

  def test_does_not_sanitize_li_elements_contained_in_ul_or_ol
    stuff = "a\n<ul><li>b</li></ul>\nc"
    assert_equal stuff, SanitizationFilter.call(stuff).to_s
  end

  def test_github_specific_protocols_are_not_removed
    stuff = '<a href="github-windows://spillthelog">Spill this yo</a> and so on'
    assert_equal stuff, SanitizationFilter.call(stuff).to_s
  end

  def test_unknown_schemes_are_removed
    stuff = '<a href="something-weird://heyyy">Wat</a> is this'
    html  = SanitizationFilter.call(stuff).to_s
    assert_equal '<a>Wat</a> is this', html
  end

  def test_standard_schemes_are_removed_if_not_specified_in_anchor_schemes
    stuff  = '<a href="http://www.example.com/">No href for you</a>'
    filter = SanitizationFilter.new(stuff, {:anchor_schemes => []})
    html   = filter.call.to_s
    assert_equal '<a>No href for you</a>', html
  end

  def test_custom_anchor_schemes_are_not_removed
    stuff  = '<a href="something-weird://heyyy">Wat</a> is this'
    filter = SanitizationFilter.new(stuff, {:anchor_schemes => ['something-weird']})
    html   = filter.call.to_s
    assert_equal stuff, html
  end

  def test_anchor_schemes_are_merged_with_other_anchor_restrictions
    stuff  = '<a href="something-weird://heyyy" ping="more-weird://hiii">Wat</a> is this'
    whitelist = {
      :elements   => ['a'],
      :attributes => {'a' => ['href', 'ping']},
      :protocols  => {'a' => {'ping' => ['http']}}
    }
    filter = SanitizationFilter.new(stuff, {:whitelist => whitelist, :anchor_schemes => ['something-weird']})
    html   = filter.call.to_s
    assert_equal '<a href="something-weird://heyyy">Wat</a> is this', html
  end

  def test_uses_anchor_schemes_from_whitelist_when_not_separately_specified
    stuff  = '<a href="something-weird://heyyy">Wat</a> is this'
    whitelist = {
      :elements   => ['a'],
      :attributes => {'a' => ['href']},
      :protocols  => {'a' => {'href' => ['something-weird']}}
    }
    filter = SanitizationFilter.new(stuff, {:whitelist => whitelist})
    html   = filter.call.to_s
    assert_equal stuff, html
  end

  def test_whitelist_contains_default_anchor_schemes
    assert_equal SanitizationFilter::WHITELIST[:protocols]['a']['href'], ['http', 'https', 'mailto', :relative, 'github-windows', 'github-mac']
  end

  def test_whitelist_from_full_constant
    stuff  = '<a href="something-weird://heyyy" ping="more-weird://hiii">Wat</a> is this'
    filter = SanitizationFilter.new(stuff, :whitelist => SanitizationFilter::FULL)
    html   = filter.call.to_s
    assert_equal 'Wat is this', html
  end

  def test_exports_default_anchor_schemes
    assert_equal SanitizationFilter::ANCHOR_SCHEMES, ['http', 'https', 'mailto', :relative, 'github-windows', 'github-mac']
  end

  def test_script_contents_are_removed
    orig = '<script>JavaScript!</script>'
    assert_equal "", SanitizationFilter.call(orig).to_s
  end

  def test_table_rows_and_cells_removed_if_not_in_table
    orig = %(<tr><td>Foo</td></tr><td>Bar</td>)
    assert_equal 'FooBar', SanitizationFilter.call(orig).to_s
  end

  def test_table_sections_removed_if_not_in_table
    orig = %(<thead><tr><td>Foo</td></tr></thead>)
    assert_equal 'Foo', SanitizationFilter.call(orig).to_s
  end

  def test_table_sections_are_not_removed
    orig = %(<table>
<thead><tr><th>Column 1</th></tr></thead>
<tfoot><tr><td>Sum</td></tr></tfoot>
<tbody><tr><td>1</td></tr></tbody>
</table>)
    assert_equal orig, SanitizationFilter.call(orig).to_s
  end
end

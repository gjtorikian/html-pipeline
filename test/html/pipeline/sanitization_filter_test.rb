require "test_helper"

class HTML::Pipeline::SanitizationFilterTest < Test::Unit::TestCase
  SanitizationFilter = HTML::Pipeline::SanitizationFilter

  def test_dependency_management
    assert_dependency "sanitization_filter", "sanitize"
  end

  def test_removing_script_tags
    orig = %(<p><img src="http://github.com/img.png" /><script></script></p>)
    html = SanitizationFilter.call(orig).to_s
    assert_no_match /script/, html
  end

  def test_removing_style_tags
    orig = %(<p><style>hey now</style></p>)
    html = SanitizationFilter.call(orig).to_s
    assert_no_match /style/, html
  end

  def test_removing_style_attributes
    orig = %(<p style='font-size:1000%'>YO DAWG</p>)
    html = SanitizationFilter.call(orig).to_s
    assert_no_match /font-size/, html
    assert_no_match /style/, html
  end

  def test_removing_script_event_handler_attributes
    orig = %(<a onclick='javascript:alert(0)'>YO DAWG</a>)
    html = SanitizationFilter.call(orig).to_s
    assert_no_match /javscript/, html
    assert_no_match /onclick/, html
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

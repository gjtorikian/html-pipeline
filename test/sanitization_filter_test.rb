# frozen_string_literal: true

require "test_helper"
require "html_pipeline/node_filter/mention_filter"

class HTMLPipeline
  class SanitizationFilterTest < Minitest::Test
    SanitizationFilter = HTMLPipeline::SanitizationFilter
    DEFAULT_CONFIG = SanitizationFilter::DEFAULT_CONFIG

    def test_removing_script_tags
      orig = %(<p><img src="http://github.com/img.png" /><script></script></p>)
      html = SanitizationFilter.call(orig, DEFAULT_CONFIG).to_s

      refute_match(/script/, html)
    end

    def test_removing_style_tags
      orig = %(<p><style>hey now</style></p>)
      html = SanitizationFilter.call(orig, DEFAULT_CONFIG).to_s

      refute_match(/style/, html)
    end

    def test_removing_style_attributes
      orig = %(<p style='font-size:1000%'>YO DAWG</p>)
      html = SanitizationFilter.call(orig, DEFAULT_CONFIG).to_s

      refute_match(/font-size/, html)
      refute_match(/style/, html)
    end

    def test_removing_script_event_handler_attributes
      orig = %(<a onclick='javascript:alert(0)'>YO DAWG</a>)
      html = SanitizationFilter.call(orig, DEFAULT_CONFIG).to_s

      refute_match(/javscript/, html)
      refute_match(/onclick/, html)
    end

    def test_sanitizes_li_elements_not_contained_in_ul_or_ol
      stuff = "a\n<li>b</li>\nc"
      html  = SanitizationFilter.call(stuff, { elements: {} }).to_s

      assert_equal("a\nb\nc", html)
    end

    def test_does_not_sanitize_li_elements_contained_in_ul_or_ol
      stuff = "a\n<ul><li>b</li></ul>\nc"

      assert_equal(stuff, SanitizationFilter.call(stuff, DEFAULT_CONFIG).to_s)
    end

    def test_github_specific_protocols_are_removed
      stuff = '<a href="github-windows://spillthelog">Spill this yo</a> and so on'

      assert_equal("<a>Spill this yo</a> and so on", SanitizationFilter.call(stuff, DEFAULT_CONFIG).to_s)
    end

    def test_unknown_schemes_are_removed
      stuff = '<a href="something-weird://heyyy">Wat</a> is this'
      html  = SanitizationFilter.call(stuff, DEFAULT_CONFIG).to_s

      assert_equal("<a>Wat</a> is this", html)
    end

    def test_allowlisted_longdesc_schemes_are_allowed
      stuff = '<img src="./foo.jpg" longdesc="http://longdesc.com">'
      html  = SanitizationFilter.call(stuff, DEFAULT_CONFIG).to_s

      assert_equal('<img src="./foo.jpg" longdesc="http://longdesc.com">', html)
    end

    def test_weird_longdesc_schemes_are_removed
      stuff = '<img src="./foo.jpg" longdesc="javascript:alert(1)">'
      html  = SanitizationFilter.call(stuff, DEFAULT_CONFIG).to_s

      assert_equal('<img src="./foo.jpg">', html)
    end

    def test_standard_schemes_are_removed_if_not_specified_in_anchor_schemes
      config = DEFAULT_CONFIG.merge(protocols: { "a" => { "href" => [] } })
      stuff  = '<a href="http://www.example.com/">No href for you</a>'
      html = SanitizationFilter.call(stuff, config)

      assert_equal("<a>No href for you</a>", html)
    end

    def test_custom_anchor_schemes_are_not_removed
      config = DEFAULT_CONFIG.merge(protocols: { "a" => { "href" => ["something-weird"] } })
      stuff  = '<a href="something-weird://heyyy">Wat</a> is this'
      html = SanitizationFilter.call(stuff, config)

      assert_equal(stuff, html)
    end

    def test_allow_svg_elements_to_be_added
      config = DEFAULT_CONFIG.dup
      frag = <<~FRAG
        <svg height="100" width="100">
        <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
        </svg>
      FRAG

      html = SanitizationFilter.call(frag, config)

      assert_equal("\n", html)

      config = {
        elements: ["svg", "circle"],
        attributes: {
          "svg" => ["width"],
          "circle" => ["cx", "cy", "r"],
        },
      }

      result = <<~FRAG
        <svg width="100">
        <circle cx="50" cy="50" r="40" />
        </svg>
      FRAG

      html = SanitizationFilter.call(frag, config)

      assert_equal(result, html)
    end

    def test_anchor_schemes_are_merged_with_other_anchor_restrictions
      stuff = '<a href="something-weird://heyyy" ping="more-weird://hiii">Wat</a> is this'
      allowlist = {
        elements: ["a"],
        attributes: { "a" => ["href"] },
        protocols: { "a" => { "href" => ["something-weird"] } },
      }
      html = SanitizationFilter.call(stuff, allowlist)

      assert_equal('<a href="something-weird://heyyy">Wat</a> is this', html)
    end

    def test_uses_anchor_schemes_from_allowlist_when_not_separately_specified
      stuff = '<a href="something-weird://heyyy">Wat</a> is this'
      allowlist = {
        elements: ["a"],
        attributes: { "a" => ["href"] },
        protocols: { "a" => { "href" => ["something-weird"] } },
      }
      html = SanitizationFilter.call(stuff, allowlist)

      assert_equal(stuff, html)
    end

    def test_allowlist_contains_default_anchor_schemes
      assert_equal(["http", "https", "mailto", :relative], SanitizationFilter::DEFAULT_CONFIG[:protocols]["a"]["href"])
    end

    def test_exports_default_anchor_schemes
      assert_equal(["http", "https", "mailto", :relative], SanitizationFilter::VALID_PROTOCOLS)
    end

    def test_script_contents_are_removed
      orig = "<script>JavaScript!</script>"

      assert_equal("", SanitizationFilter.call(orig, DEFAULT_CONFIG).to_s)
    end

    def test_table_rows_and_cells_removed_if_not_in_table
      orig = %(<tr><td>Foo</td></tr><td>Bar</td>)

      assert_equal("FooBar", SanitizationFilter.call(orig, { elements: {} }))
    end

    def test_table_sections_removed_if_not_in_table
      orig = %(<thead><tr><td>Foo</td></tr></thead>)

      assert_equal("Foo", SanitizationFilter.call(orig, { elements: {} }).to_s)
    end

    def test_table_sections_are_not_removed
      orig = %(<table>
<thead><tr><th>Column 1</th></tr></thead>
<tfoot><tr><td>Sum</td></tr></tfoot>
<tbody><tr><td>1</td></tr></tbody>
</table>)

      assert_equal(orig, SanitizationFilter.call(orig, DEFAULT_CONFIG).to_s)
    end

    def test_summary_tag_are_not_removed
      orig = %(<summary>Foo</summary>)

      assert_equal(orig, SanitizationFilter.call(orig, DEFAULT_CONFIG).to_s)
    end

    def test_details_tag_and_open_attribute_are_not_removed
      orig = %(<details open>Foo</details>)

      assert_equal(orig, SanitizationFilter.call(orig, DEFAULT_CONFIG).to_s)
    end

    def test_nested_details_tag_are_not_removed
      orig = <<-NESTED
      <details>
        <summary>Foo</summary>
        <details>
          Bar
          <summary>Baz</summary>
        </details>
        Qux
      </details>
      NESTED
      assert_equal(orig, SanitizationFilter.call(orig, DEFAULT_CONFIG).to_s)
    end

    def test_sanitization_pipeline_can_be_configured
      config = {
        elements: ["p", "pre", "code"],
      }

      pipeline = HTMLPipeline.new(
        convert_filter:
          HTMLPipeline::ConvertFilter::MarkdownFilter.new,
        sanitization_config: config,
        node_filters: [
          HTMLPipeline::NodeFilter::MentionFilter.new,
        ],
      )

      result = pipeline.call(<<~CODE)
        This is *great*, @balevine:

            some_code(:first)
      CODE

      expected = <<~HTML
        <p>This is great, <a href="/balevine" class="user-mention">@balevine</a>:</p>
        <pre><code>some_code(:first)
        </code></pre>
      HTML

      assert_equal(result[:output].to_s, expected.chomp)
    end

    def test_sanitization_pipeline_can_be_removed
      pipeline = HTMLPipeline.new(
        convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new(context: { markdown: { plugins: { syntax_highlighter: nil } } }),
        sanitization_config: nil,
        node_filters: [
          HTMLPipeline::NodeFilter::MentionFilter.new,
        ],
      )

      result = pipeline.call(<<~CODE)
        This is *great*, @balevine:

            some_code(:first)
      CODE

      expected = <<~HTML
        <p>This is <em>great</em>, <a href="/balevine" class="user-mention">@balevine</a>:</p>
        <pre><code>some_code(:first)
        </code></pre>
      HTML

      assert_equal(result[:output].to_s, expected.chomp)
    end

    def test_sanitization_pipeline_does_not_need_node_filters
      config = {
        elements: ["p", "pre", "code"],
      }

      pipeline = HTMLPipeline.new(
        convert_filter:
          HTMLPipeline::ConvertFilter::MarkdownFilter.new,
        sanitization_config: config,
      )

      result = pipeline.call(<<~CODE)
        This is *great*, @birdcar:

            some_code(:first)
      CODE

      expected = <<~HTML
        <p>This is great, @birdcar:</p>
        <pre><code>some_code(:first)
        </code></pre>
      HTML

      assert_equal(result[:output].to_s, expected.chomp)
    end

    def test_a_sanitization_only_pipeline_works
      config = Selma::Sanitizer::Config.freeze_config({
        elements: [
          "strong",
        ],
      })

      pipeline = HTMLPipeline.new(
        sanitization_config: config,
      )

      text = "<p>Some <strong>plain</strong> text</p>"
      result = pipeline.call(text)
      expected = "Some <strong>plain</strong> text"

      assert_equal(result[:output].to_s, expected)
    end
  end
end

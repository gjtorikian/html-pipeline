# frozen_string_literal: true

require "test_helper"
require "html_pipeline/convert_filter/markdown_filter"

MarkdownFilter = HTMLPipeline::ConvertFilter::MarkdownFilter

class HTMLPipeline
  class MarkdownFilterTest < Minitest::Test
    def setup
      @haiku =
        "Pointing at the moon\n" \
          "Reminded of simple things\n" \
          "Moments matter most"
      @links =
        "See http://example.org/ for more info"
      @code =
        "```\n" \
          "def hello()  " \
          "'world'" \
          "end" \
          "```"
      @header = <<~DOC
        # Words

        Some words

        ## Words

        More words?
      DOC
    end

    def test_fails_when_given_a_non_string
      assert_raises(TypeError) { MarkdownFilter.call(23, context: {}) }
    end

    def test_gfm_enabled_by_default
      doc = MarkdownFilter.call(@haiku)

      assert_equal(2, Nokogiri.parse(doc).search("br").size)
    end

    def test_disabling_hardbreaks
      doc = MarkdownFilter.call(@haiku, context: { markdown: { render: { hardbreaks: false } } })

      assert_equal(0, Nokogiri.parse(doc).search("br").size)
    end

    def test_fenced_code_blocks
      doc = MarkdownFilter.call(@code)

      assert_equal(1, Nokogiri.parse(doc).search("pre").size)
    end

    def test_fenced_code_blocks_with_language
      doc = MarkdownFilter.call(@code.sub("```", "``` ruby"))

      assert_equal(1, Nokogiri.parse(doc).search("pre").size)
      assert_equal("ruby", Nokogiri.parse(doc).search("pre").first["lang"])
    end

    def test_standard_extensions
      iframe = "<iframe src='http://www.google.com'></iframe>"
      iframe_escaped = "&lt;iframe src='http://www.google.com'>&lt;/iframe>"
      doc = MarkdownFilter.call(iframe, context: { markdown: { render: { unsafe: true } } })

      assert_equal(doc, iframe_escaped)
    end

    def test_changing_extensions
      iframe = "<iframe src='http://www.google.com'></iframe>"
      doc = MarkdownFilter.call(iframe, context: { markdown: { extension: { tagfilter: false }, render: { unsafe: true } } })

      assert_equal(doc, iframe)
    end

    def test_without_tagfilter
      options = { render: { unsafe: true }, extension: { tagfilter: false } }
      script = "<script>foobar</script>"
      results = MarkdownFilter.call(script, context: { markdown: options })

      assert_equal(results, script)
    end

    def test_renders_emoji
      html = MarkdownFilter.call(":raccoon:")
      result = "<p>🦝</p>"

      assert_equal(result, html)
    end
  end
end

class GFMTest < Minitest::Test
  def setup
    @gfm = MarkdownFilter
    @context = { markdown: { render: { unsafe: true }, plugins: { syntax_highlighter: nil } } }
  end

  def test_not_touch_single_underscores_inside_words
    assert_equal(
      "<p>foo_bar</p>",
      @gfm.call("foo_bar", context: @context),
    )
  end

  def test_not_touch_underscores_in_code_blocks
    assert_equal(
      "<pre><code>foo_bar_baz\n</code></pre>",
      @gfm.call("    foo_bar_baz", context: @context),
    )
  end

  def test_not_touch_underscores_in_pre_blocks
    assert_equal(
      "<pre>\nfoo_bar_baz\n</pre>",
      @gfm.call("<pre>\nfoo_bar_baz\n</pre>", context: @context),
    )
  end

  def test_not_touch_two_or_more_underscores_inside_words
    assert_equal(
      "<p>foo_bar_baz</p>",
      @gfm.call("foo_bar_baz", context: @context),
    )
  end

  def test_turn_newlines_into_br_tags_in_simple_cases
    assert_equal(
      "<p>foo<br />\nbar</p>",
      @gfm.call("foo  \nbar", context: @context),
    )
  end

  def test_convert_newlines_in_all_groups
    assert_equal(
      "<p>apple<br />\npear<br />\norange</p>\n" \
        "<p>ruby<br />\npython<br />\nerlang</p>",
      @gfm.call("apple  \npear  \norange  \n\nruby  \npython  \nerlang", context: @context),
    )
  end

  def test_convert_newlines_in_even_long_groups
    assert_equal(
      "<p>apple<br />\npear<br />\norange<br />\nbanana</p>\n" \
        "<p>ruby<br />\npython<br />\nerlang</p>",
      @gfm.call("apple  \npear  \norange  \nbanana  \n\nruby  \npython  \nerlang", context: @context),
    )
  end

  def test_not_convert_newlines_in_lists
    options = { extension: { header_ids: nil } }

    assert_equal(
      "<h1>foo</h1>\n<h1>bar</h1>",
      @gfm.call("# foo\n# bar", context: { markdown: options }),
    )
    assert_equal(
      "<ul>\n<li>foo</li>\n<li>bar</li>\n</ul>",
      @gfm.call("* foo\n* bar", context: { markdown: options }),
    )
  end

  def test_works_without_node_filters
    markdown = "1. Foo\n2. Bar"
    result = HTMLPipeline.new(convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new).call(markdown)[:output]

    assert_equal("<ol>\n<li>Foo</li>\n<li>Bar</li>\n</ol>", result)
  end
end

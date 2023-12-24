# frozen_string_literal: true

require "test_helper"
require "html_pipeline/node_filter/syntax_highlight_filter"

SyntaxHighlightFilter = HTMLPipeline::NodeFilter::SyntaxHighlightFilter

class HTMLPipeline
  class SyntaxHighlightFilterTest < Minitest::Test
    def test_highlight_default
      result = SyntaxHighlightFilter.call(
        "<pre>hello</pre>", context: { highlight: "coffeescript" }
      )

      doc = Nokogiri.parse(result)

      refute_empty(doc.css(".highlight"))
      refute_empty(doc.css(".highlight-coffeescript"))
    end

    def test_highlight_default_will_not_override
      result = SyntaxHighlightFilter.call(
        "<pre lang='c'>hello</pre>",  context: { highlight: "coffeescript" }
      )

      doc = Nokogiri.parse(result)

      assert_empty(doc.css(".highlight-coffeescript"))
      refute_empty(doc.css(".highlight-c"))
    end

    def test_highlight_does_not_remove_pre_tag
      result = SyntaxHighlightFilter.call(
        "<pre lang='c'>hello</pre>",  context: { highlight: "coffeescript" }
      )

      doc = Nokogiri.parse(result)

      refute_empty(doc.css("pre"))
    end

    def test_highlight_allows_optional_scope
      result = SyntaxHighlightFilter.call(
        "<pre lang='c'>hello</pre>",  context: { highlight: "coffeescript", scope: "test-scope" }
      )

      doc = Nokogiri.parse(result)

      refute_empty(doc.css("pre.test-scope"))
    end

    def test_highlight_keeps_the_pre_tags_lang
      result = SyntaxHighlightFilter.call(
        "<pre lang='c'>hello</pre>",  context: { highlight: "coffeescript" }
      )

      doc = Nokogiri.parse(result)

      refute_empty(doc.css("pre[lang=c]"))
    end
  end
end

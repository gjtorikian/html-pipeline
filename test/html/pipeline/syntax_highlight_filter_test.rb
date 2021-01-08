# frozen_string_literal: true

require 'test_helper'
require 'escape_utils'

SyntaxHighlightFilter = HTML::Pipeline::SyntaxHighlightFilter

class HTML::Pipeline::SyntaxHighlightFilterTest < Minitest::Test
  def test_highlight_default
    filter = SyntaxHighlightFilter.new \
      '<pre>hello</pre>', context: { highlight: 'coffeescript' }

    doc = filter.call
    refute_empty doc.css('.highlight')
    refute_empty doc.css('.highlight-coffeescript')
  end

  def test_highlight_default_will_not_override
    filter = SyntaxHighlightFilter.new \
      "<pre lang='c'>hello</pre>",  context: { highlight: 'coffeescript' }

    doc = filter.call
    assert_empty doc.css('.highlight-coffeescript')
    refute_empty doc.css('.highlight-c')
  end

  def test_highlight_does_not_remove_pre_tag
    filter = SyntaxHighlightFilter.new \
      "<pre lang='c'>hello</pre>",  context: { highlight: 'coffeescript' }

    doc = filter.call

    refute_empty doc.css('pre')
  end

  def test_highlight_allows_optional_scope
    filter = SyntaxHighlightFilter.new \
      "<pre lang='c'>hello</pre>",  context: { highlight: 'coffeescript', scope: 'test-scope' }

    doc = filter.call

    refute_empty doc.css('pre.test-scope')
  end

  def test_highlight_keeps_the_pre_tags_lang
    filter = SyntaxHighlightFilter.new \
      "<pre lang='c'>hello</pre>",  context: { highlight: 'coffeescript' }

    doc = filter.call

    refute_empty doc.css('pre[lang=c]')
  end

  def test_highlight_handles_nested_pre_tags
    inner_code = "<pre>console.log('i am nested!')</pre>"
    escaped = EscapeUtils.escape_html(inner_code)
    html = "<pre lang='html'>#{escaped}</pre>"
    filter = SyntaxHighlightFilter.new html, context: { highlight: 'html' }

    doc = filter.call

    assert_equal 2, doc.css('span[class=nt]').length
    assert_equal EscapeUtils.unescape_html(escaped), doc.inner_text
  end
end

require "test_helper"

SyntaxHighlightFilter = HTML::Pipeline::SyntaxHighlightFilter

class HTML::Pipeline::SyntaxHighlightFilterTest < Test::Unit::TestCase
  def test_highlight_default
    filter = SyntaxHighlightFilter.new \
      "<pre>hello</pre>", :highlight => "coffeescript"

    doc = filter.call
    assert_not_empty doc.css ".highlight-coffeescript"
  end

  def test_highlight_default_will_not_override
    filter = SyntaxHighlightFilter.new \
      "<pre lang='c'>hello</pre>", :highlight => "coffeescript"

    doc = filter.call
    assert_empty doc.css ".highlight-coffeescript"
    assert_not_empty doc.css ".highlight-c"
  end
end

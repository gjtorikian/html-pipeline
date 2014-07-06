require "test_helper"

SyntaxHighlightFilter = HTML::Pipeline::SyntaxHighlightFilter

class HTML::Pipeline::SyntaxHighlightFilterTest < Minitest::Test
  def test_highlight_default
    filter = SyntaxHighlightFilter.new \
      "<pre>hello</pre>", :highlight => "coffeescript"

    doc = filter.call
    assert !doc.css(".highlight-coffeescript").empty?
  end

  def test_highlight_default_will_not_override
    filter = SyntaxHighlightFilter.new \
      "<pre lang='c'>hello</pre>", :highlight => "coffeescript"

    doc = filter.call
    assert doc.css(".highlight-coffeescript").empty?
    assert !doc.css(".highlight-c").empty?
  end
end

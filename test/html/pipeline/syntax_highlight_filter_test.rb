require "test_helper"

class HTML::Pipeline::SyntaxHighlightFilterTest < Test::Unit::TestCase
  HighlightFilter = HTML::Pipeline::SyntaxHighlightFilter

  def filter(*args)
    HighlightFilter.call(*args)
  end

  def test_unchanged
    html = "<pre>plain</pre>"
    assert_equal html, filter(html).to_s
  end

  def test_syntax_highlighting
    html = "<pre lang=rb>a = 1</pre>"
    assert_equal_html <<-RESULT, filter(html).to_s
      <div class="highlight">
        <pre>
        <span class="n">a</span> <span class="o">=</span> <span class="mi">1</span>
        </pre>
      </div>
    RESULT
  end
end

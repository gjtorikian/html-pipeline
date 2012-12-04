require "test_helper"

class HTML::Pipeline::SyntaxHighlightFilterTest < Test::Unit::TestCase
  HighlightFilter = HTML::Pipeline::SyntaxHighlightFilter

  def filter(*args)
    HighlightFilter.call(*args)
  end

  def test_unchanged
    html = %(<pre lang="plain">I am a poem</pre>)
    assert_equal html, filter(html).to_s
  end

  def test_syntax_highlighting
    html = "<pre lang=rb>a = 1</pre>"
    assert_equal_html <<-RESULT, filter(html).to_s
      <div class="highlight"><pre>
        <span class="n">a</span> <span class="o">=</span> <span class="mi">1</span>
      </pre></div>
    RESULT
  end

  def test_explicit_lang_skips_detection
    html = "<pre lang=rb>var a = null</pre>"
    assert_equal_html <<-RESULT, filter(html).to_s
      <div class="highlight"><pre>
        <span class="n">var</span> <span class="n">a</span>
        <span class="o">=</span> <span class="n">null</span>
      </pre></div>
    RESULT
  end

  def test_detects_ruby
    html = "<pre>def foo; end</pre>"
    assert_equal_html <<-RUBY, filter(html).to_s
      <div class="highlight"><pre>
        <span class="k">def</span> <span class="nf">foo</span><span class="p">;</span>
        <span class="k">end</span>
      </pre></div>
    RUBY
  end

  def test_detects_javascript
    html = "<pre>var a = null</pre>"
    assert_equal_html <<-RESULT, filter(html).to_s
      <div class="highlight"><pre>
        <span class="kd">var</span> <span class="nx">a</span>
        <span class="o">=</span> <span class="kc">null</span>
      </pre></div>
    RESULT
  end

  def test_disable_detect
    html = "<pre>def foo; end</pre>"
    assert_equal html, filter(html, :detect_syntax => false).to_s
  end
end

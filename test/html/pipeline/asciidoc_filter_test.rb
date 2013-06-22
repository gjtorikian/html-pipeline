require 'test_helper'

AsciiDocFilter = HTML::Pipeline::AsciiDocFilter

class HTML::Pipeline::AsciiDocFilterTest < Test::Unit::TestCase

  def setup
    @doctitle_example = <<-EOS
= Sample Document
Author Name

Paragraph in preamble

== Sample Section

Paragraph in section
    EOS

    @source_code_example = <<-EOS
```ruby
def hello()
  'world'
end
```
    EOS
  end

  def test_for_document_title
    doc = AsciiDocFilter.to_document(@doctitle_example)
    assert doc.kind_of?(HTML::Pipeline::DocumentFragment)
    assert_equal 1, doc.css('h1').size
    assert_equal 1, doc.css('#preamble p').size
    assert_equal 1, doc.css('h2#sample-section').size
  end

  def test_for_lang_attribute_on_source_code_block
    doc = AsciiDocFilter.to_document(@source_code_example)
    assert doc.kind_of?(HTML::Pipeline::DocumentFragment)
    assert_equal 1, doc.search('pre').size
    assert_equal 'ruby', doc.search('pre').first['lang']
  end
  
  AsciiDocPipeline =
    HTML::Pipeline.new [
      HTML::Pipeline::AsciiDocFilter,
      HTML::Pipeline::SanitizationFilter,
      HTML::Pipeline::SyntaxHighlightFilter
    ]

  def test_syntax_highlighting
    result = {}
    AsciiDocPipeline.call(@source_code_example, {}, result)
    assert_equal_html %(<div class="highlight">
<pre><span class="k">def</span> <span class="nf">hello</span><span class="p">()</span>
  <span class="s1">'world'</span>
<span class="k">end</span></pre>
</div>), result[:output].to_s
  end

  def test_for_document_structure
    result = {}
    AsciiDocPipeline.call(@doctitle_example, {}, result)
    output = result[:output]
    assert_equal 1, output.css('h1').size
    assert_equal 1, output.css('h2').size
    assert_equal 2, output.css('p').size
  end
end

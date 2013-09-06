require "test_helper"

class HTML::Pipeline::YamlFilterTest < Test::Unit::TestCase
  MarkdownPipeline =
    HTML::Pipeline.new [
      HTML::Pipeline::YamlFilter,
      HTML::Pipeline::MarkdownFilter
    ]

  def filter(html, base_url='/', info_url=nil)
    HTML::Pipeline::YamlFilter.call(html)
  end

  def markdown_filter(html, base_url='/', info_url=nil)
    MarkdownPipeline.call(html)[:output]
  end

  def test_basic_filter
    body = "---\ntitle: A very interesting piece\n---\nWell hello there!"

    res  = filter(body)

    assert_equal res, "<table><tr><td>title</td><td>A very interesting piece</td></tr></table>\n\nWell hello there!"
  end

  def test_basic_markdown_filter
    body = "---\ntitle: A great title\n---\n**Well _hello_ there!**"

    res  = markdown_filter(body)

    assert_equal res, "<table><tr><td>title</td><td>A great title</td></tr></table>\n\n<p><strong>Well <em>hello</em> there!</strong></p>"
  end
end

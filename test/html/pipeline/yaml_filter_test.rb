require "test_helper"

class HTML::Pipeline::YamlFilterTest < Test::Unit::TestCase
  def filter(html, base_url='/', info_url=nil)
    HTML::Pipeline::YamlFilter.call(html)
  end

  def test_filtering_a_documentfragment
    body = "---\ntitle: A very interesting piece\n---\nWell hello there!"

    res  = filter(body)
  end

  MarkdownPipeline =
    HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::YamlFilter
    ]
end

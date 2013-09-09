require "test_helper"

class HTML::Pipeline::YamlFilterTest < Test::Unit::TestCase

  def load_fixture(dirname="before", filename)
    test_path = File.expand_path File.dirname(__FILE__)
    File.read("#{test_path}/fixtures/yaml_filter/#{dirname}/#{filename}").rstrip
  end

  def filter(filename)
    HTML::Pipeline::YamlFilter.call(load_fixture(filename))
  end

  def markdown_filter(filename)
    MarkdownPipeline.call(load_fixture(filename))[:output]
  end

  def test_basic_filter
    res  = filter("basic.md")

    assert_equal res, load_fixture("after", "basic.text")
  end

  def test_yaml_with_error
    body = ""
  end

  MarkdownPipeline =
    HTML::Pipeline.new [
      HTML::Pipeline::YamlFilter,
      HTML::Pipeline::MarkdownFilter
    ]

  def test_basic_markdown_filter
    res = markdown_filter("basic_with_markdown.md")

    assert_equal res, load_fixture("after", "basic_with_markdown.text")
  end
end

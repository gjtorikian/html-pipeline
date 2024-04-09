# frozen_string_literal: true

require "test_helper"
require "html_pipeline/text_filter/plain_text_input_filter"

class HTMLPipeline
  class PlainTextInputFilterTest < Minitest::Test
    PlainTextInputFilter = HTMLPipeline::TextFilter::PlainTextInputFilter

    def test_fails_when_given_a_documentfragment
      body = "<p>heyo</p>"
      doc  = Nokogiri::HTML::DocumentFragment.parse(body)
      assert_raises(TypeError) { PlainTextInputFilter.call(doc, context: {}) }
    end

    def test_wraps_input_in_a_div_element
      doc = PlainTextInputFilter.call("howdy pahtner", context: {})

      assert_equal("<div>howdy pahtner</div>", doc.to_s)
    end

    def test_html_escapes_plain_text_input
      doc = PlainTextInputFilter.call("See: <http://example.org>", context: {})

      assert_equal(
        "<div>See: &lt;http://example.org&gt;</div>",
        doc.to_s,
      )
    end

    def test_works_within_complete_pipeline
      pipeline = HTMLPipeline.new(text_filters: [HTMLPipeline::TextFilter::PlainTextInputFilter.new])
      result = pipeline.call("See: <http://example.org>")

      assert_equal(
        "<div>See: &lt;http://example.org&gt;</div>",
        result[:output],
      )
    end
  end
end

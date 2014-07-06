require "test_helper"

class HTML::Pipeline::PlainTextInputFilterTest < Minitest::Test
  PlainTextInputFilter = HTML::Pipeline::PlainTextInputFilter

  def test_fails_when_given_a_documentfragment
    body = "<p>heyo</p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)
    assert_raises(TypeError) { PlainTextInputFilter.call(doc, {}) }
  end

  def test_wraps_input_in_a_div_element
    doc = PlainTextInputFilter.call("howdy pahtner", {})
    assert_equal "<div>howdy pahtner</div>", doc.to_s
  end

  def test_html_escapes_plain_text_input
    doc = PlainTextInputFilter.call("See: <http://example.org>", {})
    assert_equal "<div>See: &lt;http://example.org&gt;</div>",
      doc.to_s
  end
end

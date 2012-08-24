require File.expand_path('../../../test_helper', __FILE__)

context "GitHub::HTML::PlainTextInputFilter" do
  PlainTextInputFilter = GitHub::HTML::PlainTextInputFilter

  test "fails when given a DocumentFragment" do
    body = "<p>heyo</p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)
    assert_raise(TypeError) { PlainTextInputFilter.call(doc, {}) }
  end

  test "wraps input in a <div> element" do
    doc = PlainTextInputFilter.call("howdy pahtner", {})
    assert doc.kind_of?(GitHub::HTML::DocumentFragment)
    assert_equal "<div>howdy pahtner</div>", doc.to_html
  end

  test "HTML escapes plain text input" do
    doc = PlainTextInputFilter.call("See: <http://example.org>", {})
    assert doc.kind_of?(GitHub::HTML::DocumentFragment)
    assert_equal "<div>See: &lt;http://example.org&gt;</div>",
      doc.to_html
  end
end

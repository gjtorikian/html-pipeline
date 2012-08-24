require File.expand_path('../../../test_helper', __FILE__)

MarkdownFilter = GitHub::HTML::MarkdownFilter

context "GitHub::HTML::MarkdownFilter" do
  fixtures do
    @haiku =
      "Pointing at the moon\n" +
      "Reminded of simple things\n" +
      "Moments matter most"
    @links =
      "See http://example.org/ for more info"
    @code =
      "```\n" +
      "def hello()" +
      "  'world'" +
      "end" +
      "```"
  end

  test "fails when given a DocumentFragment" do
    body = "<p>heyo</p>"
    doc  = GitHub::HTML.parse(body)
    assert_raise(TypeError) { MarkdownFilter.call(doc, {}) }
  end

  test "GFM enabled by default" do
    doc = MarkdownFilter.to_document(@haiku, {})
    assert doc.kind_of?(GitHub::HTML::DocumentFragment)
    assert_equal 2, doc.search('br').size
  end

  test "disabling GFM" do
    doc = MarkdownFilter.to_document(@haiku, :gfm => false)
    assert doc.kind_of?(GitHub::HTML::DocumentFragment)
    assert_equal 0, doc.search('br').size
  end

  test "fenced code blocks" do
    doc = MarkdownFilter.to_document(@code)
    assert doc.kind_of?(GitHub::HTML::DocumentFragment)
    assert_equal 1, doc.search('pre').size
  end

  test "fenced code blocks with language" do
    doc = MarkdownFilter.to_document(@code.sub("```", "``` ruby"))
    assert doc.kind_of?(GitHub::HTML::DocumentFragment)
    assert_equal 1, doc.search('pre').size
    assert_equal 'ruby', doc.search('pre').first['lang']
  end
end

context "GFM" do
  def gfm(text)
    MarkdownFilter.call(text, :gfm => true)
  end

  test "not touch single underscores inside words" do
    assert_equal "<p>foo_bar</p>",
                 gfm("foo_bar")
  end

  test "not touch underscores in code blocks" do
    assert_equal "<pre><code>foo_bar_baz\n</code></pre>",
                 gfm("    foo_bar_baz")
  end

  test "not touch underscores in pre blocks" do
    assert_equal "<pre>\nfoo_bar_baz\n</pre>",
                 gfm("<pre>\nfoo_bar_baz\n</pre>")
  end

  test "not touch two or more underscores inside words" do
    assert_equal "<p>foo_bar_baz</p>",
                 gfm("foo_bar_baz")
  end

  test "turn newlines into br tags in simple cases" do
    assert_equal "<p>foo<br>\nbar</p>",
                 gfm("foo\nbar")
  end

  test "convert newlines in all groups" do
    assert_equal "<p>apple<br>\npear<br>\norange</p>\n\n" +
                 "<p>ruby<br>\npython<br>\nerlang</p>",
                 gfm("apple\npear\norange\n\nruby\npython\nerlang")
  end

  test "convert newlines in even long groups" do
    assert_equal "<p>apple<br>\npear<br>\norange<br>\nbanana</p>\n\n" +
                 "<p>ruby<br>\npython<br>\nerlang</p>",
                 gfm("apple\npear\norange\nbanana\n\nruby\npython\nerlang")
  end

  test "not convert newlines in lists" do
    assert_equal "<h1>foo</h1>\n\n<h1>bar</h1>",
                 gfm("# foo\n# bar")
    assert_equal "<ul>\n<li>foo</li>\n<li>bar</li>\n</ul>",
                 gfm("* foo\n* bar")
  end
end

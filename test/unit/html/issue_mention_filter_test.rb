require File.expand_path('../../../test_helper', __FILE__)

context "GitHub::HTML::IssueMentionFilter" do
  IssueMentionFilter = GitHub::HTML::IssueMentionFilter

  fixtures do
    @defunkt = User.make(:login => 'defunkt')
    @mojombo = User.make(:login => 'mojombo')
    @pyberry = Repository.make(:name => 'pyberry', :owner => @defunkt)
    @fork    = @mojombo.fork(@pyberry)

    @issue   = Issue.make(:repository => @pyberry, :user => @defunkt, :number => 42)
    @issue2  = Issue.make(:repository => @pyberry, :user => @defunkt, :number => 69)
    @other   = Issue.make(:repository => @fork, :user => @defunkt, :number => 88)
  end

  def issue_link(url, text, title = nil)
    title ||= @issue.title
    url = File.join(GitHub.url, url)
    "<a href=\"#{url}\" class=\"issue-link\" title=\"#{title}\">#{text}</a>"
  end

  def replace_references(body, context={})
    @context = context
    @result = {}
    context[:repository] = @pyberry if !context.key?(:repository)
    context[:base_url]   ||= GitHub.url
    html = IssueMentionFilter.call(body, context, @result).to_s
  end

  test "global issue links" do
    body = "<p>See: defunkt/pyberry#42 for more info</p>"
    link = issue_link('/defunkt/pyberry/issues/42', 'defunkt/pyberry#42')
    assert_equal "<p>See: #{link} for more info</p>",
      replace_references(body, :repository => nil).to_s
  end

  test "global issue links in repository context" do
    body = "<p>See: defunkt/pyberry#42 for more info</p>"
    link = issue_link('/defunkt/pyberry/issues/42', 'defunkt/pyberry#42')
    assert_equal "<p>See: #{link} for more info</p>",
      replace_references(body).to_s
  end

  test "user issue links in repository context" do
    body = "<p>See: mojombo#88 for more info</p>"
    link = issue_link('/mojombo/pyberry/issues/88', 'mojombo#88', @other.title)
    assert_equal "<p>See: #{link} for more info</p>",
      replace_references(body).to_s
  end

  test "user issue links in repository context with invalid user" do
    body = "<p>See: rtomayko#42 for more info</p>"
    assert_equal body, replace_references(body).to_s
  end

  test "bare issue links in repository context" do
    body = "<p>See: #42 for more info</p>"
    link = issue_link('/defunkt/pyberry/issues/42', '#42')
    assert_equal "<p>See: #{link} for more info</p>",
      replace_references(body).to_s
    assert !@result[:issues].first.close?
  end

  test "bare issue links in repository context with invalid number" do
    body = "<p>See: #1000 for more info</p>"
    assert_equal body, replace_references(body).to_s
  end

  test "HTML injection" do
    body = "<p>See: #42 &lt;script>alert(0)&lt;/script></p>"
    link = issue_link('/defunkt/pyberry/issues/42', '#42')
    assert_equal "<p>See: #{link} &lt;script&gt;alert(0)&lt;/script&gt;</p>",
      replace_references(body).to_s

    @issue.update_attributes(:title => "<script>alert(0)</script>")
    title = "&lt;script&gt;alert(0)&lt;/script&gt;"
    link = issue_link("/defunkt/pyberry/issues/42", "#42", title)
    assert_equal "<p>See: #{link} &lt;script&gt;alert(0)&lt;/script&gt;</p>",
      replace_references(body).to_s
  end

  test "links closes #42 and whatnot" do
    link = issue_link('/defunkt/pyberry/issues/42', '#42')
    assert_equal "<p>this fixes #{link}</p>",
      replace_references("<p>this fixes #42</p>")
    assert @result[:issues].first.close?

    assert_equal "<p>this closes #{link}</p>",
      replace_references("<p>this closes #42</p>")
    assert @result[:issues].first.close?

    replace_references("<p>fix #42</p>")
    assert @result[:issues].first.close?

    replace_references("<p>fixd #42</p>")
    assert !@result[:issues].first.close?

    replace_references("<p>fixs #42</p>")
    assert !@result[:issues].first.close?

    replace_references("<p>resolves #42</p>")
    assert @result[:issues].first.close?

    replace_references("<p>resolved #42</p>")
    assert @result[:issues].first.close?

    replace_references("<p>resolve #42</p>")
    assert @result[:issues].first.close?
  end

  test "links multiple issues" do
    body = "<p>Fix all the things (#42,#69)</p>"
    html = replace_references(body)
    assert_equal 2, html.scan('<a').size
    assert_equal 2, @result[:issues].size
  end

  test "ignores unknown issues" do
    body = "<p>this fixes #1000</p>"
    assert_equal body, replace_references(body)
  end

  test "ignores mention inside of pre, code and a tags" do
    body = "<div>foo <pre>fixes #42</pre>\n</div>"
    assert_equal body, replace_references(body)

    body = "<p>foo <code>fixes #42</code></p>"
    assert_equal body, replace_references(body)

    body = "<p>foo <a href=\"http://bit.ly/AhAUB\">fixes #42</a></p>"
    assert_equal body, replace_references(body)
  end

  test "writes array of referenced issues to context hash" do
    assert replace_references("<p>closes #42 and #69</p>").include?('<a')
    assert_equal 2, @result[:issues].size
    assert @result[:issues].first.issue == @issue
    assert @result[:issues].last.issue == @issue2
  end

  test "gh-number form" do
    assert replace_references("<p>checkout GH-42 and gh-69")
    assert_equal 2, @result[:issues].size
    assert @result[:issues].first.issue == @issue
    assert @result[:issues].last.issue == @issue2
  end

  test "referencing issues in root repositories from forks" do
    assert replace_references("<p>check out #42 and #88</p>", :repository => @fork)
    assert_equal 2, @result[:issues].size
    assert_equal @issue, @result[:issues].first.issue
    assert_equal @other, @result[:issues].last.issue
    assert_equal @fork, @result[:issues].last.issue.repository
  end
end

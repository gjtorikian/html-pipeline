require File.expand_path('../../../test_helper', __FILE__)

context "GitHub::HTML::CommitMentionFilter" do
  CommitMentionFilter = GitHub::HTML::CommitMentionFilter

  fixtures do
    @defunkt = User.make(:login => 'defunkt')
    @mojombo = User.make(:login => 'mojombo')
    @pyberry = Repository.make(:name => 'pyberry', :owner => @defunkt)

    readonly_example_repo :simple, @pyberry
    
    @commit_id       = '63611721afd41f58f801d66e543d8288b4c5eb44'
    @other_commit_id = "c1800491d95c42b4e96fb83f31fe8d9230c62907"
    @bad_commit_id   = "deadbeefdecafbad"
  end

  def commit_link(url, text)
    "<a href=\"#{url}\" class=\"commit-link\">#{text}</a>"
  end

  test "global commit links" do
    body = "<p>See: defunkt/pyberry@#{@commit_id} for more info</p>"
    link =
      commit_link(
        "/defunkt/pyberry/commit/#{@commit_id}",
        "defunkt/pyberry@<tt>#{@commit_id[0,7]}</tt>"
      )
    assert_equal "<p>See: #{link} for more info</p>",
      CommitMentionFilter.call(body).to_s
  end

  test "global 7 char commit links" do
    body = "<p>See: defunkt/pyberry@#{@commit_id[0, 7]} for more info</p>"
    link =
      commit_link(
        "/defunkt/pyberry/commit/#{@commit_id[0,7]}",
        "defunkt/pyberry@<tt>#{@commit_id[0,7]}</tt>"
      )
    assert_equal "<p>See: #{link} for more info</p>",
      CommitMentionFilter.call(body).to_s
  end

  test "global commit links in repository context" do
    body = "<p>See: defunkt/pyberry@#{@commit_id} for more info</p>"
    link =
      commit_link(
        "/defunkt/pyberry/commit/#{@commit_id}",
        "defunkt/pyberry@<tt>#{@commit_id[0,7]}</tt>"
      )
    assert_equal "<p>See: #{link} for more info</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "global 7 char commit links in repository context" do
    body = "<p>See: defunkt/pyberry@#{@commit_id[0,7]} for more info</p>"
    link =
      commit_link(
        "/defunkt/pyberry/commit/#{@commit_id[0,7]}",
        "defunkt/pyberry@<tt>#{@commit_id[0,7]}</tt>"
      )
    assert_equal "<p>See: #{link} for more info</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  # XXX this is kind of dumb. we should check that the user actually has a
  # repository and that the issue exists.
  test "user commit links in repository context" do
    body = "<p>See: mojombo@#{@commit_id} for more info</p>"
    link = commit_link(
      "/mojombo/pyberry/commit/#{@commit_id}",
      "mojombo@<tt>#{@commit_id[0,7]}</tt>")
    assert_equal "<p>See: #{link} for more info</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "user 7 char commit links in repository context" do
    body = "<p>See: mojombo@#{@commit_id[0,7]} for more info</p>"
    link = commit_link(
      "/mojombo/pyberry/commit/#{@commit_id[0,7]}",
      "mojombo@<tt>#{@commit_id[0,7]}</tt>")
    assert_equal "<p>See: #{link} for more info</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "bare 7 char commit range links in repository context" do
    range = "#{@commit_id[0,7]}...#{@other_commit_id[0,7]}"
    body = "<p>That probably changed between #{range}</p>"
    compare_link = %Q[<a href="/defunkt/pyberry/compare/#{range}" class="commit-link"><tt>#{range}</tt></a>]
    assert_equal "<p>That probably changed between #{compare_link}</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "formatted bare long-SHA commit range links in repository context" do
    range      = "#{@commit_id[0,7]}...#{@other_commit_id[0,7]}"
    long_range = "#{@commit_id}...#{@other_commit_id[0,30]}"
    body = "<p>That probably changed between #{long_range}</p>"
    compare_link = %Q[<a href="/defunkt/pyberry/compare/#{long_range}" class="commit-link"><tt>#{range}</tt></a>]
    assert_equal "<p>That probably changed between #{compare_link}</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "not linking commit range using .." do
    body = "<p>That probably changed between #{@commit_id[0,7]}..#{@other_commit_id[0,7]}</p>"
    first_link = commit_link(
      "/defunkt/pyberry/commit/#{@commit_id[0,7]}",
      "<tt>#{@commit_id[0,7]}</tt>"
    )
    second_link = commit_link(
      "/defunkt/pyberry/commit/#{@other_commit_id[0,7]}",
      "<tt>#{@other_commit_id[0,7]}</tt>"
    )
    assert_equal "<p>That probably changed between #{first_link}..#{second_link}</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "not linking range involving invalid commit" do
    body = "<p>That probably changed between #{@bad_commit_id}...#{@other_commit_id[0,7]}</p>"
    second_link = commit_link(
      "/defunkt/pyberry/commit/#{@other_commit_id[0,7]}",
      "<tt>#{@other_commit_id[0,7]}</tt>"
    )
    assert_equal "<p>That probably changed between #{@bad_commit_id}...#{second_link}</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "bare commit links in repository context" do
    body = "<p>See: #{@commit_id} for more info</p>"
    link = commit_link(
      "/defunkt/pyberry/commit/#{@commit_id}",
      "<tt>#{@commit_id[0,7]}</tt>")
    assert_equal "<p>See: #{link} for more info</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "bare short commit links in repository context" do
    body = "<p>See: #{@commit_id[0, 7]} for more info</p>"
    link = commit_link(
      "/defunkt/pyberry/commit/#{@commit_id[0,7]}",
      "<tt>#{@commit_id[0,7]}</tt>")
    assert_equal "<p>See: #{link} for more info</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "HTML injection" do
    body = "<p>See: #{@commit_id} &lt;script>alert(0)&lt;script></p>"
    link = commit_link(
      "/defunkt/pyberry/commit/#{@commit_id}",
      "<tt>#{@commit_id[0,7]}</tt>")
    assert_equal "<p>See: #{link} &lt;script&gt;alert(0)&lt;script&gt;</p>",
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "not linking invalid short bare commits" do
    body = "<p>See: #{@bad_commit_id} for more info</p>"
    assert_equal body,
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "not linking bare commitish in wrong context" do
    body = "<p>Look it up at something.#{@commit_id[0,7]}.com for more info</p>"
    assert_equal body,
      CommitMentionFilter.call(body, :repository => @pyberry).to_s
  end

  test "not linking commits in pre blocks" do
    body = "<pre>#{@commit_id}\n</pre>"
    assert_equal body, CommitMentionFilter.call(body).to_s
  end

  test "not linking commits in links" do
    body = "<a>#{@commit_id}\n</a>"
    assert_equal body, CommitMentionFilter.call(body).to_s
  end

  test "not linking commits in code segments" do
    body = "<code>#{@commit_id}\n</code>"
    assert_equal body, CommitMentionFilter.call(body).to_s
  end

  test "limits to 10 mentions" do
    context = {:repository => @pyberry}
    result = {}
    shas = Array(@commit_id[0, 7]) * 11
    body = "<p>#{shas.join(" ")}</p>"
    CommitMentionFilter.call(body, context, result)
    assert_equal 10, result[:commits].size
  end
end

require File.expand_path('../../../test_helper', __FILE__)

context "GitHub::HTML::MentionFilter" do
  fixtures do
    @defunkt  = User.make :login => 'defunkt'
    @mojombo  = User.make :login => 'mojombo'
    @kneath   = User.make :login => 'kneath'
    @tmm1     = User.make :login => 'tmm1'
    @atmos    = User.make :login => 'atmos'
    @mislav   = User.make :login => 'mislav'
    @rtomayko = User.make :login => 'rtomayko'
  end

  def filter(html, base_url='/')
    GitHub::HTML::MentionFilter.call(html, :base_url => base_url)
  end

  test "filtering a DocumentFragment" do
    body = "<p>@kneath: check it out.</p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res  = filter(doc, '/')
    assert_same doc, res

    link = "<a href=\"/kneath\" class=\"user-mention\">@kneath</a>"
    assert_equal "<p>#{link}: check it out.</p>",
      res.to_html
  end

  test "filtering plain text" do
    body = "<p>@kneath: check it out.</p>"
    res  = filter(body, '/')

    link = "<a href=\"/kneath\" class=\"user-mention\">@kneath</a>"
    assert_equal "<p>#{link}: check it out.</p>",
      res.to_html
  end

  test "not replacing mentions in pre tags" do
    body = "<pre>@kneath: okay</pre>"
    assert_equal body, filter(body).to_html
  end

  test "not replacing mentions in code tags" do
    body = "<p><code>@kneath:</code> okay</p>"
    assert_equal body, filter(body).to_html
  end

  test "not replacing mentions in links" do
    body = "<p><a>@kneath</a> okay</p>"
    assert_equal body, filter(body).to_html
  end

  test "entity encoding and whatnot" do
    body = "<p>@&#x6b;neath what's up</p>"
    link = "<a href=\"/kneath\" class=\"user-mention\">@kneath</a>"
    assert_equal "<p>#{link} what's up</p>", filter(body, '/').to_html
  end

  test "HTML injection" do
    body = "<p>@kneath &lt;script>alert(0)&lt;/script></p>"
    link = "<a href=\"/kneath\" class=\"user-mention\">@kneath</a>"
    assert_equal "<p>#{link} &lt;script&gt;alert(0)&lt;/script&gt;</p>",
      filter(body, '/').to_html
  end

  MarkdownPipeline =
    GitHub::HTML::Pipeline.new [
      GitHub::HTML::MarkdownFilter,
      GitHub::HTML::MentionFilter
    ]

  def mentioned_usernames
    result = {}
    MarkdownPipeline.call(@body, {}, result)
    result[:mentioned_users].map { |user| user.to_s }
  end

  test "matches usernames in body" do
    User.make :login => 'test'
    @body = "@test how are you?"
    assert_equal %w[test], mentioned_usernames
  end

  test "matches usernames with dashes" do
    User.make :login => 'some-user'
    @body = "hi @some-user"
    assert_equal %w[some-user], mentioned_usernames
  end

  test "matches usernames followed by a single dot" do
    User.make :login => 'some-user'
    @body = "okay @some-user."
    assert_equal %w[some-user], mentioned_usernames
  end

  test "matches usernames followed by multiple dots" do
    User.make :login => 'some-user'
    @body = "okay @some-user..."
    assert_equal %w[some-user], mentioned_usernames
  end

  test "does not match email addresses" do
    @body = "aman@tmm1.net"
    assert_equal [], mentioned_usernames
  end

  test "does not match domain name looking things" do
    @body = "we need a @github.com email"
    assert_equal [], mentioned_usernames
  end

  test "does not match organization/team mentions" do
    User.make :login => 'github'
    @body = "we need to @github/enterprise know"
    assert_equal [], mentioned_usernames
  end

  test "matches colon suffixed names" do
    @body = "@tmm1: what do you think?"
    assert_equal %w[tmm1], mentioned_usernames
  end

  test "matches list of names" do
    @body = "@defunkt @atmos @kneath"
    assert_equal %w[defunkt atmos kneath], mentioned_usernames
  end

  test "matches list of names with commas" do
    @body = "/cc @defunkt, @atmos, @kneath"
    assert_equal %w[defunkt atmos kneath], mentioned_usernames
  end

  test "matches inside brackets" do
    @body = "(@mislav) and [@rtomayko]"
    assert_equal %w[mislav rtomayko], mentioned_usernames
  end

  test "ignores invalid users" do
    @body = "@defunkt @mojombo and @somedude"
    assert_equal ['defunkt', 'mojombo'], mentioned_usernames
  end

  test "returns distinct set" do
    @body = "/cc @defunkt, @atmos, @kneath, @defunkt, @defunkt"
    assert_equal %w[defunkt atmos kneath], mentioned_usernames
  end

  test "does not match inline code block with multiple code blocks" do
    @body = "something\n\n`/cc @defunkt @atmos @kneath` `/cc @atmos/atmos`"
    assert_equal %w[], mentioned_usernames
  end
end

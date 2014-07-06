require "test_helper"

class HTML::Pipeline::MentionFilterTest < Minitest::Test
  def filter(html, base_url='/', info_url=nil)
    HTML::Pipeline::MentionFilter.call(html, :base_url => base_url, :info_url => info_url)
  end

  def test_filtering_a_documentfragment
    body = "<p>@kneath: check it out.</p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res  = filter(doc, '/')
    assert_same doc, res

    link = "<a href=\"/kneath\" class=\"user-mention\">@kneath</a>"
    assert_equal "<p>#{link}: check it out.</p>",
      res.to_html
  end

  def test_filtering_plain_text
    body = "<p>@kneath: check it out.</p>"
    res  = filter(body, '/')

    link = "<a href=\"/kneath\" class=\"user-mention\">@kneath</a>"
    assert_equal "<p>#{link}: check it out.</p>",
      res.to_html
  end

  def test_not_replacing_mentions_in_pre_tags
    body = "<pre>@kneath: okay</pre>"
    assert_equal body, filter(body).to_html
  end

  def test_not_replacing_mentions_in_code_tags
    body = "<p><code>@kneath:</code> okay</p>"
    assert_equal body, filter(body).to_html
  end

  def test_not_replacing_mentions_in_links
    body = "<p><a>@kneath</a> okay</p>"
    assert_equal body, filter(body).to_html
  end

  def test_entity_encoding_and_whatnot
    body = "<p>@&#x6b;neath what's up</p>"
    link = "<a href=\"/kneath\" class=\"user-mention\">@kneath</a>"
    assert_equal "<p>#{link} what's up</p>", filter(body, '/').to_html
  end

  def test_html_injection
    body = "<p>@kneath &lt;script>alert(0)&lt;/script></p>"
    link = "<a href=\"/kneath\" class=\"user-mention\">@kneath</a>"
    assert_equal "<p>#{link} &lt;script&gt;alert(0)&lt;/script&gt;</p>",
      filter(body, '/').to_html
  end

  def test_links_to_nothing_when_no_info_url_given
    body = "<p>How do I @mention someone?</p>"
    assert_equal "<p>How do I @mention someone?</p>",
      filter(body, '/').to_html
  end

  def test_links_to_more_info_when_info_url_given
    body = "<p>How do I @mention someone?</p>"
    link = "<a href=\"https://github.com/blog/821\" class=\"user-mention\">@mention</a>"
    assert_equal "<p>How do I #{link} someone?</p>",
      filter(body, '/', 'https://github.com/blog/821').to_html
  end

  MarkdownPipeline =
    HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::MentionFilter
    ]

  def mentioned_usernames
    result = {}
    MarkdownPipeline.call(@body, {}, result)
    result[:mentioned_usernames]
  end

  def test_matches_usernames_in_body
    @body = "@test how are you?"
    assert_equal %w[test], mentioned_usernames
  end

  def test_matches_usernames_with_dashes
    @body = "hi @some-user"
    assert_equal %w[some-user], mentioned_usernames
  end

  def test_matches_usernames_followed_by_a_single_dot
    @body = "okay @some-user."
    assert_equal %w[some-user], mentioned_usernames
  end

  def test_matches_usernames_followed_by_multiple_dots
    @body = "okay @some-user..."
    assert_equal %w[some-user], mentioned_usernames
  end

  def test_does_not_match_email_addresses
    @body = "aman@tmm1.net"
    assert_equal [], mentioned_usernames
  end

  def test_does_not_match_domain_name_looking_things
    @body = "we need a @github.com email"
    assert_equal [], mentioned_usernames
  end

  def test_does_not_match_organization_team_mentions
    @body = "we need to @github/enterprise know"
    assert_equal [], mentioned_usernames
  end

  def test_matches_colon_suffixed_names
    @body = "@tmm1: what do you think?"
    assert_equal %w[tmm1], mentioned_usernames
  end

  def test_matches_list_of_names
    @body = "@defunkt @atmos @kneath"
    assert_equal %w[defunkt atmos kneath], mentioned_usernames
  end

  def test_matches_list_of_names_with_commas
    @body = "/cc @defunkt, @atmos, @kneath"
    assert_equal %w[defunkt atmos kneath], mentioned_usernames
  end

  def test_matches_inside_brackets
    @body = "(@mislav) and [@rtomayko]"
    assert_equal %w[mislav rtomayko], mentioned_usernames
  end

  def test_doesnt_ignore_invalid_users
    @body = "@defunkt @mojombo and @somedude"
    assert_equal ['defunkt', 'mojombo', 'somedude'], mentioned_usernames
  end

  def test_returns_distinct_set
    @body = "/cc @defunkt, @atmos, @kneath, @defunkt, @defunkt"
    assert_equal %w[defunkt atmos kneath], mentioned_usernames
  end

  def test_does_not_match_inline_code_block_with_multiple_code_blocks
    @body = "something\n\n`/cc @defunkt @atmos @kneath` `/cc @atmos/atmos`"
    assert_equal %w[], mentioned_usernames
  end

  def test_mention_at_end_of_parenthetical_sentence
    @body = "(We're talking 'bout @ymendel.)"
    assert_equal %w[ymendel], mentioned_usernames
  end
end

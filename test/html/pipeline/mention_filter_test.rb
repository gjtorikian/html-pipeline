# frozen_string_literal: true

require 'test_helper'

class HTML::Pipeline::MentionFilterTest < Minitest::Test
  def setup
    @filter = HTML::Pipeline::MentionFilter
    @context = { base_url: '/', info_url: nil, username_pattern: nil }

    @pipeline = HTML::Pipeline.new([
                                     HTML::Pipeline::MarkdownFilter,
                                     HTML::Pipeline::MentionFilter
                                   ])
  end

  def mentioned_usernames(body) # rubocop:disable Minitest/TestMethodName
    result = {}
    @pipeline.call(body, result: result)
    result[:mentioned_usernames]
  end

  def test_filtering_a_documentfragment
    body = '<p>@kneath: check it out.</p>'
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res  = @filter.call(doc, context: @context)
    assert_same doc, res

    link = '<a href="/kneath" class="user-mention">@kneath</a>'
    assert_equal "<p>#{link}: check it out.</p>",
                 res.to_html
  end

  def test_filtering_plain_text
    body = '<p>@kneath: check it out.</p>'
    res  = @filter.call(body, context: @context)

    link = '<a href="/kneath" class="user-mention">@kneath</a>'
    assert_equal "<p>#{link}: check it out.</p>",
                 res.to_html
  end

  def test_not_replacing_mentions_in_pre_tags
    body = '<pre>@kneath: okay</pre>'
    assert_equal body, @filter.call(body, context: @context).to_html
  end

  def test_not_replacing_mentions_in_code_tags
    body = '<p><code>@kneath:</code> okay</p>'
    assert_equal body, @filter.call(body, context: @context).to_html
  end

  def test_not_replacing_mentions_in_style_tags
    body = '<style>@media (min-width: 768px) { color: red; }</style>'
    assert_equal body, @filter.call(body, context: @context).to_html
  end

  def test_not_replacing_mentions_in_links
    body = '<p><a>@kneath</a> okay</p>'
    assert_equal body, @filter.call(body, context: @context).to_html
  end

  def test_entity_encoding_and_whatnot
    body = "<p>@&#x6b;neath what's up</p>"
    link = '<a href="/kneath" class="user-mention">@kneath</a>'
    assert_equal "<p>#{link} what's up</p>", @filter.call(body, context: @context).to_html
  end

  def test_html_injection
    body = '<p>@kneath &lt;script>alert(0)&lt;/script></p>'
    link = '<a href="/kneath" class="user-mention">@kneath</a>'
    assert_equal "<p>#{link} &lt;script&gt;alert(0)&lt;/script&gt;</p>",
                 @filter.call(body, context: @context).to_html
  end

  def test_base_url_slash
    body = '<p>Hi, @jch!</p>'
    link = '<a href="/jch" class="user-mention">@jch</a>'
    assert_equal "<p>Hi, #{link}!</p>",
                 @filter.call(body, context: { base_url: '/' }).to_html
  end

  def test_base_url_under_custom_route
    body = '<p>Hi, @jch!</p>'
    link = '<a href="/userprofile/jch" class="user-mention">@jch</a>'
    assert_equal "<p>Hi, #{link}!</p>",
                 @filter.call(body, context: @context.merge({ base_url: '/userprofile' })).to_html
  end

  def test_base_url_slash_with_tilde
    body = '<p>Hi, @jch!</p>'
    link = '<a href="/~jch" class="user-mention">@jch</a>'
    assert_equal "<p>Hi, #{link}!</p>",
                 @filter.call(body, context: @context.merge({ base_url: '/~' })).to_html
  end

  def test_matches_usernames_in_body
    body = '@test how are you?'
    assert_equal %w[test], mentioned_usernames(body)
  end

  def test_matches_usernames_with_dashes
    body = 'hi @some-user'
    assert_equal %w[some-user], mentioned_usernames(body)
  end

  def test_matches_usernames_followed_by_a_single_dot
    body = 'okay @some-user.'
    assert_equal %w[some-user], mentioned_usernames(body)
  end

  def test_matches_usernames_followed_by_multiple_dots
    body = 'okay @some-user...'
    assert_equal %w[some-user], mentioned_usernames(body)
  end

  def test_does_not_match_email_addresses
    body = 'aman@tmm1.net'
    assert_equal [], mentioned_usernames(body)
  end

  def test_does_not_match_domain_name_looking_things
    body = 'we need a @github.com email'
    assert_equal [], mentioned_usernames(body)
  end

  def test_does_not_match_organization_team_mentions
    body = 'we need to @github/enterprise know'
    assert_equal [], mentioned_usernames(body)
  end

  def test_matches_colon_suffixed_names
    body = '@tmm1: what do you think?'
    assert_equal %w[tmm1], mentioned_usernames(body)
  end

  def test_matches_list_of_names
    body = '@defunkt @atmos @kneath'
    assert_equal %w[defunkt atmos kneath], mentioned_usernames(body)
  end

  def test_matches_list_of_names_with_commas
    body = '/cc @defunkt, @atmos, @kneath'
    assert_equal %w[defunkt atmos kneath], mentioned_usernames(body)
  end

  def test_matches_inside_brackets
    body = '(@mislav) and [@rtomayko]'
    assert_equal %w[mislav rtomayko], mentioned_usernames(body)
  end

  def test_doesnt_ignore_invalid_users
    body = '@defunkt @mojombo and @somedude'
    assert_equal %w[defunkt mojombo somedude], mentioned_usernames(body)
  end

  def test_returns_distinct_set
    body = '/cc @defunkt, @atmos, @kneath, @defunkt, @defunkt'
    assert_equal %w[defunkt atmos kneath], mentioned_usernames(body)
  end

  def test_does_not_match_inline_code_block_with_multiple_code_blocks
    body = "something\n\n`/cc @defunkt @atmos @kneath` `/cc @atmos/atmos`"
    assert_equal %w[], mentioned_usernames(body)
  end

  def test_mention_at_end_of_parenthetical_sentence
    body = "(We're talking 'bout @ymendel.)"
    assert_equal %w[ymendel], mentioned_usernames(body)
  end

  def test_username_pattern_can_be_customized
    body = '<p>@_abc: test.</p>'
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res  = @filter.call(doc, context: { base_url: '/', username_pattern: /(_[a-z]{3})/ })

    link = '<a href="/_abc" class="user-mention">@_abc</a>'
    assert_equal "<p>#{link}: test.</p>",
                 res.to_html
  end

  def test_filter_does_not_create_a_new_object_for_default_username_pattern
    body = '<div>@test</div>'
    doc = Nokogiri::HTML::DocumentFragment.parse(body)

    @filter.call(doc.clone)
    pattern_count = HTML::Pipeline::MentionFilter::MENTION_PATTERNS.length
    @filter.call(doc.clone)

    assert_equal pattern_count, HTML::Pipeline::MentionFilter::MENTION_PATTERNS.length
    @filter.call(doc.clone, context: { username_pattern: /test/ })
    assert_equal pattern_count + 1, HTML::Pipeline::MentionFilter::MENTION_PATTERNS.length
  end

  def test_mention_link_filter
    filter = HTML::Pipeline::MentionFilter.new nil
    expected = "<a href='/hubot' class='user-mention'>@hubot</a>"
    assert_equal expected, filter.mention_link_filter('@hubot')
  end
end

# frozen_string_literal: true

require 'test_helper'

class HTML::Pipeline::TeamMentionFilterTest < Minitest::Test
  def setup
    @filter = HTML::Pipeline::TeamMentionFilter

    @pipeline =
      HTML::Pipeline.new [
        HTML::Pipeline::MarkdownFilter,
        HTML::Pipeline::TeamMentionFilter
      ]
  end

  def mentioned_teams(body) # rubocop:disable Minitest/TestMethodName
    result = {}
    @pipeline.call(body, result: result)
    result[:mentioned_teams]
  end

  def test_filtering_plain_text
    body = '<p>@github/team: check it out.</p>'
    res  = @filter.call(body, context: { base_url: '/' })

    link = '<a href="/github/team" class="team-mention">@github/team</a>'
    assert_equal "<p>#{link}: check it out.</p>",
                 res.to_html
  end

  def test_filtering_a_documentfragment
    body = '<p>@github/team: check it out.</p>'
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res  = @filter.call(doc, context: { base_url: '/' })
    assert_same doc, res

    link = '<a href="/github/team" class="team-mention">@github/team</a>'
    assert_equal "<p>#{link}: check it out.</p>",
                 res.to_html
  end

  def test_not_replacing_mentions_in_pre_tags
    body = '<pre>@github/team: okay</pre>'
    assert_equal body, @filter.call(body).to_html
  end

  def test_not_replacing_mentions_in_code_tags
    body = '<p><code>@github/team:</code> okay</p>'
    assert_equal body, @filter.call(body).to_html
  end

  def test_not_replacing_mentions_in_style_tags
    body = '<style>@github/team (min-width: 768px) { color: red; }</style>'
    assert_equal body, @filter.call(body).to_html
  end

  def test_not_replacing_mentions_in_links
    body = '<p><a>@github/team</a> okay</p>'
    assert_equal body, @filter.call(body).to_html
  end

  def test_entity_encoding_and_whatnot
    body = "<p>@github&#47team what's up</p>"
    link = '<a href="/github/team" class="team-mention">@github/team</a>'
    assert_equal "<p>#{link} what's up</p>", @filter.call(body, context: { base_url: '/' }).to_html
  end

  def test_html_injection
    body = '<p>@github/team &lt;script>alert(0)&lt;/script></p>'
    link = '<a href="/github/team" class="team-mention">@github/team</a>'
    assert_equal "<p>#{link} &lt;script&gt;alert(0)&lt;/script&gt;</p>",
                 @filter.call(body, context: { base_url: '/' }).to_html
  end

  def test_links_to_nothing_with_user_mention
    body = '<p>Hi, @kneath</p>'
    assert_equal '<p>Hi, @kneath</p>',
                 @filter.call(body, context: { base_url: '/' }).to_html
  end

  def test_base_url_slash
    body = '<p>Hi, @github/team!</p>'
    link = '<a href="/github/team" class="team-mention">@github/team</a>'
    assert_equal "<p>Hi, #{link}!</p>",
                 @filter.call(body, context: { base_url: '/' }).to_html
  end

  def test_base_url_under_custom_route
    body = '<p>Hi, @org/team!</p>'
    link = '<a href="www.github.com/org/team" class="team-mention">@org/team</a>'
    assert_equal "<p>Hi, #{link}!</p>",
                 @filter.call(body, context: { base_url: 'www.github.com' }).to_html
  end

  def test_base_url_slash_with_tilde
    body = '<p>Hi, @github/team!</p>'
    link = '<a href="/~github/team" class="team-mention">@github/team</a>'
    assert_equal "<p>Hi, #{link}!</p>",
                 @filter.call(body, context: { base_url: '/~' }).to_html
  end

  def test_multiple_team_mentions
    body = '<p>Hi, @github/whale and @github/donut!</p>'
    link_whale = '<a href="/github/whale" class="team-mention">@github/whale</a>'
    link_donut = '<a href="/github/donut" class="team-mention">@github/donut</a>'
    assert_equal "<p>Hi, #{link_whale} and #{link_donut}!</p>",
                 @filter.call(body).to_html
  end

  def test_matches_teams_in_body
    body = '@test/team how are you?'
    assert_equal %w[team], mentioned_teams(body)
  end

  def test_matches_orgs_with_dashes
    body = 'hi @some-org/team'
    assert_equal %w[team], mentioned_teams(body)
  end

  def test_matches_teams_with_dashes
    body = 'hi @github/some-team'
    assert_equal %w[some-team], mentioned_teams(body)
  end

  def test_matches_teams_followed_by_a_single_dot
    body = 'okay @github/team.'
    assert_equal %w[team], mentioned_teams(body)
  end

  def test_matches_teams_followed_by_multiple_dots
    body = 'okay @github/team...'
    assert_equal %w[team], mentioned_teams(body)
  end

  def test_does_not_match_email_addresses
    body = 'aman@tmm1.net'
    assert_equal [], mentioned_teams(body)
  end

  def test_does_not_match_domain_name_looking_things
    body = 'we need a @github.com email'
    assert_equal [], mentioned_teams(body)
  end

  def test_does_not_match_user_mentions
    body = 'we need to @enterprise know'
    assert_equal [], mentioned_teams(body)
  end

  def test_matches_colon_suffixed_team_names
    body = '@github/team: what do you think?'
    assert_equal %w[team], mentioned_teams(body)
  end

  def test_matches_list_of_teams
    body = '@github/whale @github/donut @github/green'
    assert_equal %w[whale donut green], mentioned_teams(body)
  end

  def test_matches_list_of_teams_with_commas
    body = '/cc @github/whale, @github/donut, @github/green'
    assert_equal %w[whale donut green], mentioned_teams(body)
  end

  def test_matches_inside_brackets
    body = '(@github/whale) and [@github/donut]'
    assert_equal %w[whale donut], mentioned_teams(body)
  end

  def test_returns_distinct_set
    body = '/cc @github/whale, @github/donut, @github/whale, @github/whale'
    assert_equal %w[whale donut], mentioned_teams(body)
  end

  def test_does_not_match_inline_code_block_with_multiple_code_blocks
    body = "something\n\n`/cc @github/whale @github/donut @github/green` `/cc @donut/donut`"
    assert_equal %w[], mentioned_teams(body)
  end

  def test_mention_at_end_of_parenthetical_sentence
    body = "(We're talking 'bout @some-org/some-team.)"
    assert_equal %w[some-team], mentioned_teams(body)
  end

  def test_team_pattern_can_be_customized
    body = '<p>@_abc/XYZ: test</p>'
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res  = @filter.call(doc, context: { team_pattern: %r{@(_[a-z]{3})/([A-Z]{3})} })

    link = '<a href="/_abc/XYZ" class="team-mention">@_abc/XYZ</a>'
    assert_equal "<p>#{link}: test</p>",
                 res.to_html
  end

  def test_mention_link_filter
    filter = HTML::Pipeline::TeamMentionFilter.new nil
    expected = "<a href='/bot/hubot' class='team-mention'>@bot/hubot</a>"
    assert_equal expected, filter.mention_link_filter('@bot/hubot')
  end
end

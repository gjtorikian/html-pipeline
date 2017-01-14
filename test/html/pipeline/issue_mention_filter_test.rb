require "test_helper"

class HTML::Pipeline::IssueMentionFilterTest < Minitest::Test
  def filter(html, base_url='/', issueid_pattern=nil)
    HTML::Pipeline::IssueMentionFilter.call(html, :base_url => base_url, :issueid_pattern => issueid_pattern)
  end

  def test_filtering_a_documentfragment
    body = "<p>#1234: check it out.</p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res  = filter(doc, '/')
    assert_same doc, res

    link = "<a href=\"/1234\" class=\"issue-mention\">#1234</a>"
    assert_equal "<p>#{link}: check it out.</p>",
      res.to_html
  end

  def test_filtering_plain_text
    body = "<p>#1234: check it out.</p>"
    res  = filter(body, '/')

    link = "<a href=\"/1234\" class=\"issue-mention\">#1234</a>"
    assert_equal "<p>#{link}: check it out.</p>",
      res.to_html
  end

  def test_not_replacing_mentions_in_pre_tags
    body = "<pre>#1234: okay</pre>"
    assert_equal body, filter(body).to_html
  end

  def test_not_replacing_mentions_in_code_tags
    body = "<p><code>#1234:</code> okay</p>"
    assert_equal body, filter(body).to_html
  end

  def test_not_replacing_mentions_in_style_tags
    body = "<style>@media (min-width: 768px) { color: red; }</style>"
    assert_equal body, filter(body).to_html
  end

  def test_not_replacing_mentions_in_links
    body = "<p><a>#1234</a> okay</p>"
    assert_equal body, filter(body).to_html
  end

  def test_html_injection
    body = "<p>#1234 &lt;script>alert(0)&lt;/script></p>"
    link = "<a href=\"/1234\" class=\"issue-mention\">#1234</a>"
    assert_equal "<p>#{link} &lt;script&gt;alert(0)&lt;/script&gt;</p>",
      filter(body, '/').to_html
  end

  def test_base_url_slash
    body = "<p>Hi, #561!</p>"
    link = "<a href=\"/561\" class=\"issue-mention\">#561</a>"
    assert_equal "<p>Hi, #{link}!</p>",
      filter(body, '/').to_html
  end

  def test_base_url_under_custom_route
    body = "<p>Hi, #561!</p>"
    link = "<a href=\"/issues/561\" class=\"issue-mention\">#561</a>"
    assert_equal "<p>Hi, #{link}!</p>",
      filter(body, '/issues').to_html
  end

  def test_base_url_slash_with_tilde
    body = "<p>Hi, #561!</p>"
    link = "<a href=\"/~561\" class=\"issue-mention\">#561</a>"
    assert_equal "<p>Hi, #{link}!</p>",
      filter(body, '/~').to_html
  end

  MarkdownPipeline =
    HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::IssueMentionFilter
    ]

  def mentioned_issueids
    result = {}
    MarkdownPipeline.call(@body, {}, result)
    result[:mentioned_issueids]
  end

  def test_matches_issueids_in_body
    @body = "#8756 how are you?"
    assert_equal %w[8756], mentioned_issueids
  end

  def test_matches_issueids_followed_by_a_single_dot
    @body = "okay #9567."
    assert_equal %w[9567], mentioned_issueids
  end

  def test_matches_issueids_followed_by_multiple_dots
    @body = "okay #9567..."
    assert_equal %w[9567], mentioned_issueids
  end


  def test_matches_colon_suffixed_names
    @body = "#1234: what do you think?"
    assert_equal %w[1234], mentioned_issueids
  end

  def test_matches_list_of_names
    @body = "#5634 #8856 #1234"
    assert_equal %w[5634 8856 1234], mentioned_issueids
  end

  def test_matches_list_of_names_with_commas
    @body = "#5634, #8856, #1234"
    assert_equal %w[5634 8856 1234], mentioned_issueids
  end

  def test_matches_inside_brackets
    @body = "(#5634) and  [#8856]"
    assert_equal %w[5634 8856], mentioned_issueids
  end

  def test_doesnt_ignore_invalid_issues
    @body = "#5634 #8856 #1234444444"
    assert_equal %w[5634 8856 1234444444], mentioned_issueids
  end

  def test_returns_distinct_set
    @body = "#5634 #8856 #1234 #5634 #8856 #1234"
    assert_equal %w[5634 8856 1234], mentioned_issueids
  end

  def test_does_not_match_inline_code_block_with_multiple_code_blocks
    @body = "something\n\n`#4456 #3267 #1234`"
    assert_equal %w[], mentioned_issueids
  end

  def test_mention_at_end_of_parenthetical_sentence
    @body = "(We're talking 'bout #2568.)"
    assert_equal %w[2568], mentioned_issueids
  end

  def test_issueid_pattern_can_be_customized
    body = "<p>#_987: issue.</p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res  = filter(doc, '/', /(_[0-9]{3})/)

    link = "<a href=\"/_987\" class=\"issue-mention\">#_987</a>"
    assert_equal "<p>#{link}: issue.</p>",
      res.to_html
  end

  def test_filter_does_not_create_a_new_object_for_default_issueid_pattern
    body = "<div>#8756</div>"
    doc = Nokogiri::HTML::DocumentFragment.parse(body)

    filter(doc.clone, '/', nil)
    pattern_count = HTML::Pipeline::IssueMentionFilter::MentionPatterns.length
    filter(doc.clone, '/', nil)

    assert_equal pattern_count, HTML::Pipeline::IssueMentionFilter::MentionPatterns.length
    filter(doc.clone, '/', /8756/)
    assert_equal pattern_count + 1, HTML::Pipeline::IssueMentionFilter::MentionPatterns.length
  end
end

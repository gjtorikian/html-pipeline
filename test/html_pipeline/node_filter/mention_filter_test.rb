# frozen_string_literal: true

require "test_helper"

class HTMLPipeline
  class MentionFilterTest < Minitest::Test
    def setup
      @filter = HTMLPipeline::NodeFilter::MentionFilter
      @context = { base_url: "/", info_url: nil, username_pattern: nil }

      @pipeline = HTMLPipeline.new(
        convert_filter:
                HTMLPipeline::ConvertFilter::MarkdownFilter.new,
        node_filters: [
          HTMLPipeline::NodeFilter::MentionFilter.new,
        ],
      )
    end

    def mentioned_usernames(body)
      result = {}
      result = @pipeline.call(body, result: result)
      result[:mentioned_usernames]
    end
    @pipeline =
      def test_filtering_plain_text
        body = "<p>@kneath: check it out.</p>"
        res  = @filter.call(body, context: @context)

        link = '<a href="/kneath" class="user-mention">@kneath</a>'

        assert_equal(
          "<p>#{link}: check it out.</p>",
          res,
        )
      end

    def test_not_replacing_mentions_in_pre_tags
      body = "<pre>@kneath: okay</pre>"

      assert_equal(body, @filter.call(body, context: @context))
    end

    def test_not_replacing_mentions_in_code_tags
      body = "<p><code>@kneath:</code> okay</p>"

      assert_equal(body, @filter.call(body, context: @context))
    end

    def test_not_replacing_mentions_in_style_tags
      body = "<style>@media (min-width: 768px) { color: red; }</style>"

      assert_equal(body, @filter.call(body, context: @context))
    end

    def test_not_replacing_mentions_in_links
      body = "<p><a>@kneath</a> okay</p>"

      assert_equal(body, @filter.call(body, context: @context))
    end

    def test_entity_encoding_and_whatnot
      body = "<p>@&#x6b;neath what's up</p>"

      assert_equal(body, @filter.call(body, context: @context))
    end

    def test_html_injection
      body = "<p>@kneath &lt;script>alert(0)&lt;/script></p>"
      link = '<a href="/kneath" class="user-mention">@kneath</a>'

      assert_equal(
        "<p>#{link} &lt;script>alert(0)&lt;/script></p>",
        @filter.call(body, context: @context),
      )
    end

    def test_base_url_slash
      body = "<p>Hi, @jch!</p>"
      link = '<a href="/jch" class="user-mention">@jch</a>'

      assert_equal(
        "<p>Hi, #{link}!</p>",
        @filter.call(body, context: { base_url: "/" }),
      )
    end

    def test_base_url_under_custom_route
      body = "<p>Hi, @jch!</p>"
      link = '<a href="/userprofile/jch" class="user-mention">@jch</a>'

      assert_equal(
        "<p>Hi, #{link}!</p>",
        @filter.call(body, context: @context.merge({ base_url: "/userprofile" })),
      )
    end

    def test_base_url_slash_with_tilde
      body = "<p>Hi, @jch!</p>"
      link = '<a href="/~jch" class="user-mention">@jch</a>'

      assert_equal(
        "<p>Hi, #{link}!</p>",
        @filter.call(body, context: @context.merge({ base_url: "/~" })),
      )
    end

    def test_base_url_slash_with_at
      body = "<p>Hi, @jch!</p>"
      link = '<a href="/@jch" class="user-mention">@jch</a>'

      assert_equal(
        "<p>Hi, #{link}!</p>",
        @filter.call(body, context: @context.merge({ base_url: "/@" })),
      )
    end

    def test_matches_usernames_in_body
      body = "@test how are you?"

      assert_equal(["test"], mentioned_usernames(body))
    end

    def test_matches_usernames_with_dashes
      body = "hi @some-user"

      assert_equal(["some-user"], mentioned_usernames(body))
    end

    def test_matches_usernames_followed_by_a_single_dot
      body = "okay @some-user."

      assert_equal(["some-user"], mentioned_usernames(body))
    end

    def test_matches_usernames_followed_by_multiple_dots
      body = "okay @some-user..."

      assert_equal(["some-user"], mentioned_usernames(body))
    end

    def test_does_not_match_email_addresses
      body = "aman@tmm1.net"

      assert_empty(mentioned_usernames(body))
    end

    def test_does_not_match_domain_name_looking_things
      body = "we need a @github.com email"

      assert_empty(mentioned_usernames(body))
    end

    def test_does_not_match_organization_team_mentions
      body = "we need to @github/enterprise know"

      assert_empty(mentioned_usernames(body))
    end

    def test_matches_colon_suffixed_names
      body = "@tmm1: what do you think?"

      assert_equal(["tmm1"], mentioned_usernames(body))
    end

    def test_matches_list_of_names
      body = "@defunkt @atmos @kneath"

      assert_equal(["defunkt", "atmos", "kneath"], mentioned_usernames(body))
    end

    def test_matches_list_of_names_with_commas
      body = "/cc @defunkt, @atmos, @kneath"

      assert_equal(["defunkt", "atmos", "kneath"], mentioned_usernames(body))
    end

    def test_matches_inside_brackets
      body = "(@mislav) and [@rtomayko]"

      assert_equal(["mislav", "rtomayko"], mentioned_usernames(body))
    end

    def test_doesnt_ignore_invalid_users
      body = "@defunkt @mojombo and @somedude"

      assert_equal(["defunkt", "mojombo", "somedude"], mentioned_usernames(body))
    end

    def test_returns_distinct_set
      body = "/cc @defunkt, @atmos, @kneath, @defunkt, @defunkt"

      assert_equal(["defunkt", "atmos", "kneath"], mentioned_usernames(body))
    end

    def test_does_not_match_inline_code_block_with_multiple_code_blocks
      body = "something\n\n`/cc @defunkt @atmos @kneath` `/cc @atmos/atmos`"

      assert_empty(mentioned_usernames(body))
    end

    def test_mention_at_end_of_parenthetical_sentence
      body = "(We're talking 'bout @ymendel.)"

      assert_equal(["ymendel"], mentioned_usernames(body))
    end

    def test_username_pattern_can_be_customized
      body = "<p>@_abc: test.</p>"

      res  = @filter.call(body, context: { base_url: "/", username_pattern: /(_[a-z]{3})/ })

      link = '<a href="/_abc" class="user-mention">@_abc</a>'

      assert_equal(
        "<p>#{link}: test.</p>",
        res,
      )
    end

    def test_filter_does_not_create_a_new_object_for_default_username_pattern
      body = "<div>@test</div>"

      @filter.call(body.dup)
      pattern_count = HTMLPipeline::NodeFilter::MentionFilter::MENTION_PATTERNS.length

      @filter.call(body.dup)

      assert_equal(pattern_count, HTMLPipeline::NodeFilter::MentionFilter::MENTION_PATTERNS.length)

      @filter.call(body.clone, context: { username_pattern: /test/ })

      assert_equal(pattern_count + 1, HTMLPipeline::NodeFilter::MentionFilter::MENTION_PATTERNS.length)
    end

    def test_mention_link_filter
      result = HTMLPipeline::NodeFilter::MentionFilter.call("<p>@hubot</p>")
      expected = '<p><a href="/hubot" class="user-mention">@hubot</a></p>'

      assert_equal(expected, result)
    end
  end
end

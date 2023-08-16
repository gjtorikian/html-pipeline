# frozen_string_literal: true

require "test_helper"
require "html_pipeline/node_filter/emoji_filter"

EmojiFilterFilter = HTMLPipeline::NodeFilter::EmojiFilter
class HTMLPipeline
  class EmojiFilterTest < Minitest::Test
    def setup
      @emoji_filter = HTMLPipeline::NodeFilter::EmojiFilter
    end

    def test_emojify
      orig = "<p>:armenia:</p>"
      result = @emoji_filter.call(orig, context: { asset_root: "https://foo.com" })

      assert_match("https://foo.com/emoji/unicode/1f1e6-1f1f2.png", result)
    end

    def test_uri_encoding
      result = @emoji_filter.call("<p>:+1:</p>", context: { asset_root: "https://foo.com" })

      assert_match("https://foo.com/emoji/unicode/1f44d.png", result)
    end

    def test_required_context_validation
      exception = assert_raises(ArgumentError) do
        @emoji_filter.call("", context: {})
      end

      assert_match(/:asset_root/, exception.message)
    end

    def test_custom_asset_path
      result = @emoji_filter.call("<p>:+1:</p>", context: { asset_path: ":file_name", asset_root: "https://foo.com" })

      assert_match("https://foo.com/unicode/1f44d.png", result)
    end

    def test_not_emojify_in_code_tags
      body = "<code>:shipit:</code>"
      result = @emoji_filter.call(body, context: { asset_root: "https://foo.com" })

      assert_equal(body, result)
    end

    def test_not_emojify_in_tt_tags
      body = "<tt>:shipit:</tt>"
      result = @emoji_filter.call(body, context: { asset_root: "https://foo.com" })

      assert_equal(body, result)
    end

    def test_not_emojify_in_pre_tags
      body = "<pre>:shipit:</pre>"
      result = @emoji_filter.call(body, context: { asset_root: "https://foo.com" })

      assert_equal(body, result)
    end

    def test_not_emojify_in_custom_single_tag_foo
      body = "<foo>:armenia:</foo>"
      result = @emoji_filter.call(body, context: { asset_root: "https://foo.com", ignored_ancestor_tags: ["foo"] })

      assert_equal(body, result)
    end

    def test_not_emojify_in_custom_multiple_tags_foo_and_bar
      body = "<bar>:armenia:</bar>"
      result = @emoji_filter.call(body, context: { asset_root: "https://foo.com", ignored_ancestor_tags: ["foo", "bar"] })

      assert_equal(body, result)
    end

    def test_img_tag_attributes
      body = "<p>:armenia:</p>"
      result = @emoji_filter.call(body, context: { asset_root: "https://foo.com" })

      assert_match(%(<img class="emoji" title=":armenia:" alt=":armenia:" src="https://foo.com/emoji/unicode/1f1e6-1f1f2.png" height="20" width="20" align="absmiddle">), result)
    end

    def test_img_tag_attributes_can_be_customized
      body = "<p>:armenia:</p>"
      result = @emoji_filter.call(body, context: { asset_root: "https://foo.com", img_attrs: Hash("draggable" => "false", "height" => nil, "width" => nil, "align" => nil) })

      assert_match(%(<img class="emoji" title=":armenia:" alt=":armenia:" src="https://foo.com/emoji/unicode/1f1e6-1f1f2.png" draggable="false">), result)
    end

    def test_img_attrs_value_can_accept_proclike_object
      remove_colons = ->(name) { name.delete(":") }
      body = "<p>:armenia:</p>"
      result = @emoji_filter.call(body, context: { asset_root: "https://foo.com", img_attrs: Hash("title" => remove_colons) })

      assert_match(%(<img class="emoji" title="armenia" alt=":armenia:" src="https://foo.com/emoji/unicode/1f1e6-1f1f2.png" height="20" width="20" align="absmiddle">), result)
    end

    def test_img_attrs_can_accept_symbolized_keys
      body = "<p>:armenia:</p>"
      result = @emoji_filter.call(body, context: { asset_root: "https://foo.com", img_attrs: Hash(draggable: false, height: nil, width: nil, align: nil) })

      assert_match(%(<img class="emoji" title=":armenia:" alt=":armenia:" src="https://foo.com/emoji/unicode/1f1e6-1f1f2.png" draggable="false">), result)
    end

    def test_works_with_gemoji
      require "gemojione"

      HTMLPipeline::NodeFilter::EmojiFilter.stub(:gemoji_loaded?, false) do
        body = "<span>:flag_ar:</span>"
        result = HTMLPipeline::NodeFilter::EmojiFilter.call(body, context: { asset_root: "https://foo.com" })

        assert_equal(%(<span><img class="emoji" title=":flag_ar:" alt=":flag_ar:" src="https://foo.com/emoji/1f1e6-1f1f7.png" height="20" width="20" align="absmiddle"></span>), result)
      end
    end

    def test_gemoji_can_accept_symbolized_keys
      require "gemojione"
      HTMLPipeline::NodeFilter::EmojiFilter.stub(:gemoji_loaded?, false) do
        body = "<span>:flag_ar:</span>"
        result = HTMLPipeline::NodeFilter::EmojiFilter.call(body, context: { asset_root: "https://coolwebsite.com", img_attrs: Hash(draggable: false, height: nil, width: nil, align: nil) })

        assert_equal(%(<span><img class="emoji" title=":flag_ar:" alt=":flag_ar:" src="https://coolwebsite.com/emoji/1f1e6-1f1f7.png" draggable="false"></span>), result)
      end
    end
  end
end

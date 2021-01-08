# frozen_string_literal: true

require 'test_helper'

class HTML::Pipeline::EmojiFilterTest < Minitest::Test
  def setup
    @emoji_filter = HTML::Pipeline::EmojiFilter
  end

  def test_emojify
    filter = @emoji_filter.new('<p>:shipit:</p>', context: { asset_root: 'https://foo.com' })
    doc = filter.call
    assert_match 'https://foo.com/emoji/shipit.png', doc.search('img').attr('src').value
  end

  def test_uri_encoding
    filter = @emoji_filter.new('<p>:+1:</p>', context: { asset_root: 'https://foo.com' })
    doc = filter.call
    assert_match 'https://foo.com/emoji/unicode/1f44d.png', doc.search('img').attr('src').value
  end

  def test_required_context_validation
    exception = assert_raises(ArgumentError) do
      @emoji_filter.call('', context: {})
    end
    assert_match(/:asset_root/, exception.message)
  end

  def test_custom_asset_path
    filter = @emoji_filter.new('<p>:+1:</p>', context: { asset_path: ':file_name', asset_root: 'https://foo.com' })
    doc = filter.call
    assert_match 'https://foo.com/unicode/1f44d.png', doc.search('img').attr('src').value
  end

  def test_not_emojify_in_code_tags
    body = '<code>:shipit:</code>'
    filter = @emoji_filter.new(body, context: { asset_root: 'https://foo.com' })
    doc = filter.call
    assert_equal body, doc.to_html
  end

  def test_not_emojify_in_tt_tags
    body = '<tt>:shipit:</tt>'
    filter = @emoji_filter.new(body, context: { asset_root: 'https://foo.com' })
    doc = filter.call
    assert_equal body, doc.to_html
  end

  def test_not_emojify_in_pre_tags
    body = '<pre>:shipit:</pre>'
    filter = @emoji_filter.new(body, context: { asset_root: 'https://foo.com' })
    doc = filter.call
    assert_equal body, doc.to_html
  end

  def test_not_emojify_in_custom_single_tag_foo
    body = '<foo>:shipit:</foo>'
    filter = @emoji_filter.new(body, context: { asset_root: 'https://foo.com', ignored_ancestor_tags: %w[foo] })
    doc = filter.call
    assert_equal body, doc.to_html
  end

  def test_not_emojify_in_custom_multiple_tags_foo_and_bar
    body = '<bar>:shipit:</bar>'
    filter = @emoji_filter.new(body, context: { asset_root: 'https://foo.com', ignored_ancestor_tags: %w[foo bar] })
    doc = filter.call
    assert_equal body, doc.to_html
  end

  def test_img_tag_attributes
    body = ':shipit:'
    filter = @emoji_filter.new(body, context: { asset_root: 'https://foo.com' })
    doc = filter.call
    assert_equal %(<img class="emoji" title=":shipit:" alt=":shipit:" src="https://foo.com/emoji/shipit.png" height="20" width="20" align="absmiddle">), doc.to_html
  end

  def test_img_tag_attributes_can_be_customized
    body = ':shipit:'
    filter = @emoji_filter.new(body, context: { asset_root: 'https://foo.com', img_attrs: Hash('draggable' => 'false', 'height' => nil, 'width' => nil, 'align' => nil) })
    doc = filter.call
    assert_equal %(<img class="emoji" title=":shipit:" alt=":shipit:" src="https://foo.com/emoji/shipit.png" draggable="false">), doc.to_html
  end

  def test_img_attrs_value_can_accept_proclike_object
    remove_colons = ->(name) { name.delete(':') }
    body = ':shipit:'
    filter = @emoji_filter.new(body, context: { asset_root: 'https://foo.com', img_attrs: Hash('title' => remove_colons) })
    doc = filter.call
    assert_equal %(<img class="emoji" title="shipit" alt=":shipit:" src="https://foo.com/emoji/shipit.png" height="20" width="20" align="absmiddle">), doc.to_html
  end

  def test_img_attrs_can_accept_symbolized_keys
    body = ':shipit:'
    filter = @emoji_filter.new(body, context: { asset_root: 'https://foo.com', img_attrs: Hash(draggable: false, height: nil, width: nil, align: nil) })
    doc = filter.call
    assert_equal %(<img class="emoji" title=":shipit:" alt=":shipit:" src="https://foo.com/emoji/shipit.png" draggable="false">), doc.to_html
  end

  def test_works_with_gemoji
    require 'gemojione'

    HTML::Pipeline::EmojiFilter.stub :gemoji_loaded?, false do
      body = ':flag_ar:'
      filter = HTML::Pipeline::EmojiFilter.new(body, context: { asset_root: 'https://foo.com' })
      doc = filter.call
      assert_equal %(<img class="emoji" title=":flag_ar:" alt=":flag_ar:" src="https://foo.com/emoji/1f1e6-1f1f7.png" height="20" width="20" align="absmiddle">), doc.to_html
    end
  end

  def test_gemoji_can_accept_symbolized_keys
    require 'gemojione'
    HTML::Pipeline::EmojiFilter.stub :gemoji_loaded?, false do
      body = ':flag_ar:'
      filter = HTML::Pipeline::EmojiFilter.new(body, context: { asset_root: 'https://coolwebsite.com', img_attrs: Hash(draggable: false, height: nil, width: nil, align: nil) })
      doc = filter.call
      assert_equal %(<img class="emoji" title=":flag_ar:" alt=":flag_ar:" src="https://coolwebsite.com/emoji/1f1e6-1f1f7.png" draggable="false">), doc.to_html
    end
  end
end

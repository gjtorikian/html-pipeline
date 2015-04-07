# encoding: utf-8

require 'test_helper'

class HTML::Pipeline::AnchorTargetFilterTest < Minitest::Test
  AnchorTargetFilter = HTML::Pipeline::AnchorTargetFilter

  def filter(body, options={})
    AnchorTargetFilter.to_html(body, options)
  end

  def test_anchors_are_added_properly
    assert_equal %(<a href="https://www.github.com" target="_default">GitHub</a>),
          filter(%(<a href="https://www.github.com">GitHub</a>))
  end

  def test_uses_context_target_over_default_target
    assert_equal %(<a href="https://www.github.com" target="test">GitHub</a>),
          filter(%(<a href="https://www.github.com">GitHub</a>),
                 target: 'test')
  end

  def test_only_changes_anchor_tags
    assert_equal %(<blink>test!</blink>),
          filter(%(<blink>test!</blink>))
  end

  def test_replaces_existing_target
    assert_equal %(<a href="https://www.github.com" target="_default">GitHub</a>),
          filter(%(<a href="https://www.github.com" target="test">GitHub</a>))
  end

  def test_context_target_false_removes_targets
    assert_equal %(<a href="https://www.github.com">GitHub</a>),
          filter(%(<a href="https://www.github.com" target="test">GitHub</a>),
                 target: false)
  end
end

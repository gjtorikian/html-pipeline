require "test_helper"

class HTML::Pipeline::SyntaxHighlightFilterTest < Test::Unit::TestCase
  def test_dependency_management
    assert_dependency_management_error "syntax_highlight_filter", "github-linguist"
  end
end

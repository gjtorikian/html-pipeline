require "test_helper"

class HTML::Pipeline::EmailReplyFilterTest < Test::Unit::TestCase
  def test_dependency_management
    assert_dependency "email_reply_filter", "escape_utils"
  end
end

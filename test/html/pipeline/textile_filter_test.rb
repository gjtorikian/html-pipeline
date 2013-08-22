require "test_helper"

class HTML::Pipeline::TextileFilterTest < Test::Unit::TestCase
  def test_dependency_management
    assert_dependency_management_error "textile_filter", "RedCloth"
  end
end

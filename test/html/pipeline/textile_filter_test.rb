require "test_helper"

class HTML::Pipeline::TextileFilterTest < Test::Unit::TestCase
  def test_dependency_management
    assert_dependency "textile_filter", "RedCloth"
  end
end

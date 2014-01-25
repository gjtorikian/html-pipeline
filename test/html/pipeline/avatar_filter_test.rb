require "test_helper"

class HTML::Pipeline::AvatarFilterTest < Test::Unit::TestCase
  AvatarFilter = HTML::Pipeline::AvatarFilter

  def test_required_concrete_implementation
    exception = assert_raise(NotImplementedError) {
      AvatarFilter.call("<p>$jch$</p>", { :avatar_service => Object.new })
    }
    assert_equal "HTML::Pipeline::AvatarFilter cannot respond to: avatar_image_link_filter", exception.message
  end
end

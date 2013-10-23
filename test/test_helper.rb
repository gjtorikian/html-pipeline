require 'bundler/setup'
require 'html/pipeline'
require 'test/unit'

require 'active_support/core_ext/string'
require 'active_support/core_ext/object/try'

module TestHelpers
  # Asserts that `needle` is not a member of `haystack`, where
  # `haystack` is any object that responds to `include?`.
  def assert_doesnt_include(needle, haystack, message = nil)
    error = '<?> included in <?>'
    message = build_message(message, error, needle.to_s, Array(haystack).map(&:to_s))

    assert_block message do
      !haystack.include?(needle)
    end
  end

  # Asserts that `needle` is a member of `haystack`, where
  # `haystack` is any object that responds to `include?`.
  def assert_includes(needle, haystack, message = nil)
    error = '<?> not included in <?>'
    message = build_message(message, error, needle.to_s, Array(haystack).map(&:to_s))

    assert_block message do
      haystack.include?(needle)
    end
  end

  # Asserts that two html fragments are equivalent. Attribute order
  # will be ignored.
  def assert_equal_html(expected, actual)
    assert_equal Nokogiri::HTML::DocumentFragment.parse(expected).to_hash,
                 Nokogiri::HTML::DocumentFragment.parse(actual).to_hash
  end
end

Test::Unit::TestCase.send(:include, TestHelpers)

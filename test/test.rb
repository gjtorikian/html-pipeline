module HTML
  class Pipeline
    # Support Minitest 5 or Minitest 4
    class Test < defined?(::MiniTest::Test) ? ::MiniTest::Test : ::Minitest::Unit::TestCase
      # Asserts that `needle` is a member of `haystack`, where
      # `haystack` is any object that responds to `include?`.
      def assert_include(needle, haystack)
        error = "<#{needle.to_s}> not included in <#{Array(haystack).map(&:to_s)}>"
        assert(haystack.include?(needle), error)
      end

      # Asserts that two html fragments are equivalent. Attribute order
      # will be ignored.
      def assert_equal_html(expected, actual)
        assert_equal Nokogiri::HTML::DocumentFragment.parse(expected).to_hash,
                     Nokogiri::HTML::DocumentFragment.parse(actual).to_hash
      end
    end
  end
end

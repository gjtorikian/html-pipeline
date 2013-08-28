require "bundler/setup"
require "html/pipeline"
require "test/unit"

require "active_support/core_ext/object/try"
require "active_support/xml_mini/nokogiri" # convert Documents to hashes

module TestHelpers
  # Asserts that `needle` is not a member of `haystack`, where
  # `haystack` is any object that responds to `include?`.
  def assert_doesnt_include(needle, haystack, message = nil)
    error = "<?> included in <?>"
    message = build_message(message, error, needle.to_s, Array(haystack).map(&:to_s))

    assert_block message do
      !haystack.include?(needle)
    end
  end

  # Asserts that `needle` is a member of `haystack`, where
  # `haystack` is any object that responds to `include?`.
  def assert_includes(needle, haystack, message = nil)
    error = "<?> not included in <?>"
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

  # Asserts that when a Filter is loaded without its dependencies installed,
  # a HTML::Pipeline::Filter::MissingDependencyException is raised with a
  # message describing the problem and a fix.
  def assert_dependency(filter_name, gem_name)
    Kernel.module_eval do
      def require(name)
        raise LoadError
      end
    end

    exception = assert_raise HTML::Pipeline::Filter::MissingDependencyException do
      load File.join(File.dirname(__FILE__), "..", "lib", "html", "pipeline", "#{filter_name}.rb")
    end

    assert_equal exception.message,
      "Missing html-pipeline dependency: Please add `#{gem_name}` to your Gemfile; see html-pipeline Gemfile for version."
  end
end

Test::Unit::TestCase.send(:include, TestHelpers)

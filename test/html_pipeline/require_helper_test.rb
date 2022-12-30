# frozen_string_literal: true

require "test_helper"

class HTMLPipeline
  class RequireHelperTest < Minitest::Test
    def test_works_with_existing_dependency
      HTMLPipeline.require_dependency("rake", "SomeClass")
    end

    def test_works_with_existing_dependencies
      HTMLPipeline.require_dependencies(["old_sql", "nokogiri"], "SomeClass")

      assert_predicate(HTMLPipeline, :nokogiri_loaded?)
      refute_predicate(HTMLPipeline, :old_sql_loaded?)
    end

    def test_raises_mising_dependency_error
      assert_raises(HTMLPipeline::MissingDependencyError) do
        HTMLPipeline.require_dependency("non-existant", "SomeClass")
      end
    end

    def test_raises_mising_dependencies_error
      assert_raises(HTMLPipeline::MissingDependencyError) do
        HTMLPipeline.require_dependencies(["non-existant", "something"], "SomeClass")
      end
    end

    def test_raises_dependency_error_including_message
      error = assert_raises(HTMLPipeline::MissingDependencyError) do
        HTMLPipeline.require_dependency("non-existant", "SomeClass")
      end

      assert_includes(error.message, "Missing dependency 'non-existant' for SomeClass. See README.md for details.")
    end

    def test_raises_dependencies_error_including_message
      error = assert_raises(HTMLPipeline::MissingDependencyError) do
        HTMLPipeline.require_dependencies(["non-existant", "something"], "SomeClass")
      end

      assert_includes(error.message, "Missing all dependencies 'non-existant, something' for SomeClass. See README.md for details.")
    end

    def test_raises_error_includes_underlying_message
      error = assert_raises(HTMLPipeline::MissingDependencyError) do
        HTMLPipeline.require_dependency("non-existant", "SomeClass")
      end

      assert_includes(error.message, "LoadError: cannot load such file")
    end
  end
end

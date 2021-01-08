# frozen_string_literal: true

require 'test_helper'

class HTML::Pipeline::RequireHelperTest < Minitest::Test
  def test_works_with_existing_dependency
    HTML::Pipeline.require_dependency('rake', 'SomeClass')
  end

  def test_works_with_existing_dependencies
    HTML::Pipeline.require_dependencies(%w[old_sql nokogiri], 'SomeClass')
    assert HTML::Pipeline.nokogiri_loaded?
    refute HTML::Pipeline.old_sql_loaded?
  end

  def test_raises_mising_dependency_error
    assert_raises HTML::Pipeline::MissingDependencyError do
      HTML::Pipeline.require_dependency('non-existant', 'SomeClass')
    end
  end

  def test_raises_mising_dependenccies_error
    assert_raises HTML::Pipeline::MissingDependencyError do
      HTML::Pipeline.require_dependencies(%w[non-existant something], 'SomeClass')
    end
  end

  def test_raises_dependency_error_including_message
    error = assert_raises(HTML::Pipeline::MissingDependencyError) do
      HTML::Pipeline.require_dependency('non-existant', 'SomeClass')
    end
    assert_includes(error.message, "Missing dependency 'non-existant' for SomeClass. See README.md for details.")
  end

  def test_raises_dependencies_error_including_message
    error = assert_raises(HTML::Pipeline::MissingDependencyError) do
      HTML::Pipeline.require_dependencies(%w[non-existant something], 'SomeClass')
    end
    assert_includes(error.message, "Missing all dependencies 'non-existant, something' for SomeClass. See README.md for details.")
  end

  def test_raises_error_includes_underlying_message
    error = assert_raises HTML::Pipeline::MissingDependencyError do
      HTML::Pipeline.require_dependency('non-existant', 'SomeClass')
    end
    assert_includes(error.message, 'LoadError: cannot load such file')
  end
end

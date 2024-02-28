# frozen_string_literal: true

require "bundler/setup"
require "html_pipeline"

require "minitest/autorun"
require "minitest/pride"
require "minitest/focus"

require "awesome_print"

require "nokogiri"

module TestHelpers
end

Minitest::Test.include(TestHelpers)

class TestTextFilter < HTMLPipeline::TextFilter
  # class << self
  def call(input, context: {}, result: {})
    input.reverse
  end
  # end
end

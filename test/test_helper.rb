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

class TestReverseFilter < HTMLPipeline::TextFilter
  def call(input, context: {}, result: {})
    input.reverse
  end
end

# bolds any instance of the word yeH
class YehBolderFilter < HTMLPipeline::TextFilter
  def call(input, context: {}, result: {})
    input.gsub("yeH", "**yeH**") unless context[:bolded] == false
  end
end

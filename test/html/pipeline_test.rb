require "test_helper"
require "helpers/mocked_instrumentation_service"

class HTML::PipelineTest < Test::Unit::TestCase
  Pipeline = HTML::Pipeline
  class TestFilter
    def self.call(input, context, result)
      input
    end
  end

  def setup
    @context = {}
    @result_class = Hash
    @pipeline = Pipeline.new [TestFilter], @context, @result_class
  end

  def test_filter_instrumentation
    service = MockedInstrumentationService.new
    @pipeline.instrumentation_service = service
    filter("hello")
    event, payload, res = service.events.pop
    assert event, "event expected"
    assert_equal "call_filter.html_pipeline", event
    assert_equal TestFilter.name, payload[:filter]
  end

  def filter(input)
    @pipeline.call(input)
  end
end

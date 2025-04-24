# frozen_string_literal: true

require "test_helper"
require "helpers/mocked_instrumentation_service"
require "html_pipeline/node_filter/image_max_width_filter"
require "html_pipeline/node_filter/mention_filter"
require "html_pipeline/convert_filter/markdown_filter"

class HTMLPipelineTest < Minitest::Test
  def setup
    @default_context = {}
    @pipeline = HTMLPipeline.new(text_filters: [TestReverseFilter.new], default_context: @default_context)
  end

  def test_filter_instrumentation
    service = MockedInstrumentationService.new
    events = service.subscribe("call_filter.html_pipeline")
    @pipeline.instrumentation_service = service
    body = "hello"
    @pipeline.call(body)
    event, payload, = events.pop

    assert(event, "event expected")
    assert_equal("call_filter.html_pipeline", event)
    assert_equal(TestReverseFilter.name, payload[:filter])
    assert_equal(@pipeline.class.name, payload[:pipeline])
    assert_equal(body.reverse, payload[:result][:output])
  end

  def test_pipeline_instrumentation
    service = MockedInstrumentationService.new
    events = service.subscribe("call_text_filters.html_pipeline")
    @pipeline.instrumentation_service = service
    body = "hello"
    @pipeline.call(body)
    event, payload, = events.pop

    assert(event, "event expected")
    assert_equal("call_text_filters.html_pipeline", event)

    assert_equal(@pipeline.text_filters.map { |x| x.class.name }, payload[:text_filters])
    assert_equal(@pipeline.class.name, payload[:pipeline])
    assert_equal(body.reverse, payload[:result][:output])
  end

  def test_default_instrumentation_service
    service = "default"
    HTMLPipeline.default_instrumentation_service = service
    pipeline = HTMLPipeline.new(text_filters: [], default_context: @default_context)

    assert_equal(service, pipeline.instrumentation_service)
  ensure
    HTMLPipeline.default_instrumentation_service = nil
  end

  def test_setup_instrumentation
    assert_nil(@pipeline.instrumentation_service)

    service = MockedInstrumentationService.new
    events = service.subscribe("call_text_filters.html_pipeline")
    name = "foo"
    @pipeline.setup_instrumentation(name, service: service)

    assert_equal(service, @pipeline.instrumentation_service)
    assert_equal(name, @pipeline.instrumentation_name)

    body = "foo"
    @pipeline.call(body)

    event, payload, = events.pop

    assert(event, "expected event")
    assert_equal(name, payload[:pipeline])
    assert_equal(body.reverse, payload[:result][:output])
  end

  def test_incorrect_text_filters
    assert_raises(HTMLPipeline::InvalidFilterError) do
      HTMLPipeline.new(text_filters: [HTMLPipeline::NodeFilter::MentionFilter.new], default_context: @default_context)
    end
  end

  def test_incorrect_convert_filter
    assert_raises(HTMLPipeline::InvalidFilterError) do
      HTMLPipeline.new(convert_filter: HTMLPipeline::NodeFilter::ImageMaxWidthFilter, default_context: @default_context)
    end
  end

  def test_convert_filter_needed_for_text_and_html_filters
    assert_raises(HTMLPipeline::InvalidFilterError) do
      HTMLPipeline.new(
        text_filters: [TestReverseFilter.new],
        node_filters: [
          HTMLPipeline::NodeFilter::MentionFilter.new,
        ],
        default_context: @default_context,
      )
    end
  end

  def test_incorrect_node_filters
    assert_raises(HTMLPipeline::InvalidFilterError) do
      HTMLPipeline.new(node_filters: [HTMLPipeline::ConvertFilter::MarkdownFilter], default_context: @default_context)
    end
  end

  def test_just_text_filters
    text = "Hey there, @billy."

    pipeline = HTMLPipeline.new(
      text_filters: [TestReverseFilter.new],
      convert_filter: nil,
    )
    result = pipeline.call(text)[:output]

    assert_equal(".yllib@ ,ereht yeH", result)
  end

  def test_kitchen_sink
    text = "Hey there, @billy. Love to see <marquee>yah</marquee>!"

    pipeline = HTMLPipeline.new(
      text_filters: [TestReverseFilter.new, YehBolderFilter.new],
      convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new,
      node_filters: [HTMLPipeline::NodeFilter::MentionFilter.new],
    )
    result = pipeline.call(text)[:output]

    assert_equal("<p>!&gt;eeuqram/eeuqram&lt; ees ot evoL .yllib@ ,ereht <strong>yeH</strong></p>", result)
  end

  def test_context_is_carried_over_in_call
    text = "yeH! I _think_ <marquee>@gjtorikian is ~great~</marquee>!"

    pipeline = HTMLPipeline.new(
      text_filters: [YehBolderFilter.new],
      convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new,
      node_filters: [HTMLPipeline::NodeFilter::MentionFilter.new],
    )
    result = pipeline.call(text)[:output]

    # note:
    # - yeH is bolded
    # - strikethroughs are rendered
    # - mentions are not linked
    assert_equal("<p><strong>yeH</strong>! I <em>think</em> <a href=\"/gjtorikian\" class=\"user-mention\">@gjtorikian</a> is <del>great</del>!</p>", result)

    context = {
      bolded: false,
      markdown: { extension: { strikethrough: false } },
      base_url: "http://your-domain.com",
    }
    result_with_context = pipeline.call(text, context: context)[:output]

    # note:
    # - yeH is not bolded
    # - strikethroughs are not rendered
    # - mentions are linked
    assert_equal("<p>yeH! I <em>think</em> <a href=\"http://your-domain.com/gjtorikian\" class=\"user-mention\">@gjtorikian</a> is ~great~!</p>", result_with_context)
  end

  def test_text_filter_instance_context_is_carried_over_in_call
    text = "yeH! I _think_ <marquee>@gjtorikian is ~great~</marquee>!"

    pipeline = HTMLPipeline.new(
      text_filters: [YehBolderFilter.new(context: { bolded: false })],
      convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new,
      node_filters: [HTMLPipeline::NodeFilter::MentionFilter.new],
    )

    result = pipeline.call(text)[:output]

    # note:
    # - yeH is not bolded due to previous context
    assert_equal("<p>yeH! I <em>think</em> <a href=\"/gjtorikian\" class=\"user-mention\">@gjtorikian</a> is <del>great</del>!</p>", result)
  end

  def test_convert_filter_instance_context_is_carried_over_in_call
    text = "yeH! I _think_ <marquee>@gjtorikian is ~great~</marquee>!"

    pipeline = HTMLPipeline.new(
      text_filters: [YehBolderFilter.new],
      convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new(context: { extension: { strikethrough: false } }),
      node_filters: [HTMLPipeline::NodeFilter::MentionFilter.new],
    )

    result = pipeline.call(text)[:output]

    # note:
    # - strikethroughs are not rendered due to previous context
    assert_equal("<p><strong>yeH</strong>! I <em>think</em> <a href=\"/gjtorikian\" class=\"user-mention\">@gjtorikian</a> is <del>great</del>!</p>", result)
  end

  def test_node_filter_instance_context_is_carried_over_in_call
    text = "yeH! I _think_ <marquee>@gjtorikian is ~great~</marquee>!"

    pipeline = HTMLPipeline.new(
      text_filters: [YehBolderFilter.new],
      convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new,
      node_filters: [HTMLPipeline::NodeFilter::MentionFilter.new(context: { base_url: "http://your-domain.com" })],
    )

    result = pipeline.call(text)[:output]

    # note:
    # - mentions are linked
    assert_equal("<p><strong>yeH</strong>! I <em>think</em> <a href=\"http://your-domain.com/gjtorikian\" class=\"user-mention\">@gjtorikian</a> is <del>great</del>!</p>", result)
  end

  def test_mention_and_team_mention_node_filters_are_applied
    text = "Hey there, @billy. This one goes out to the @cool/dev team!"

    pipeline = HTMLPipeline.new(
      convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new,
      node_filters: [
        HTMLPipeline::NodeFilter::MentionFilter.new,
        HTMLPipeline::NodeFilter::TeamMentionFilter.new,
      ],
    )
    result = pipeline.call(text)[:output]

    assert_equal("<p>Hey there, <a href=\"/billy\" class=\"user-mention\">@billy</a>. This one goes out to the <a href=\"/cool/dev\" class=\"team-mention\">@cool/dev</a> team!</p>", result)
  end
end

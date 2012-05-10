module GitHub::HTML
  class BodyContent
    def initialize(body, context, pipeline)
      @body = body
      @context = context
      @pipeline = pipeline
    end

    def output
      @output ||= @pipeline.call @body, @context
    end

    def document
      @document ||= GitHub::HTML.parse output
    end
  end
end

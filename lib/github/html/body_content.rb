module GitHub::HTML
  class BodyContent
    attr_reader :result
    def initialize(body, context, pipeline)
      @body = body
      @context = context
      @pipeline = pipeline
    end

    def result
      @result ||= @pipeline.call @body, @context
    end

    def output
      @output ||= result[:output]
    end

    def document
      @document ||= GitHub::HTML.parse output
    end
  end
end

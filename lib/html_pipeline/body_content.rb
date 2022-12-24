# frozen_string_literal: true

class HTMLPipeline
  # Public: Runs a String of content through an HTML processing pipeline.
  class BodyContent
    # Public: Initialize a BodyContent.
    #
    # body     - A String body.
    # context  - A Hash of context options for the filters.
    # pipeline - A HTMLPipeline object with one or more Filters.
    def initialize(body, context, pipeline)
      @body = body
      @context = context
      @pipeline = pipeline
    end

    # Public: Gets the memoized result of the body content as it passed through
    # the Pipeline.
    #
    # Returns a Hash, or something similar as defined by @pipeline.result_class.
    def result
      @result ||= @pipeline.call(@body, @context)
    end

    # Public: Gets the updated body from the Pipeline result.
    #
    # Returns a String.
    def output
      @output ||= result[:output]
    end
  end
end

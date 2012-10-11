module HTML::Pipeline
  # Contruct a pipeline for running multiple HTML filters.
  #
  # filters      - Array of Filter objects. Each must respond to call(doc,
  #                context) and return the modified DocumentFragment or a
  #                String containing HTML markup. Filters are performed in the
  #                order provided.
  # default_context - The default context hash. Values specified here will be merged
  #                over any values sent in by individual pipeline runs.
  # result_class - The default Class of the result object for individual
  #                calls.  Default: Hash.  Protip:  Pass in a Struct to get
  #                some semblence of type safety.
  class Pipeline
    # Public: Returns an Array of Filter objects for this Pipeline.
    attr_reader :filters

    def initialize(filters, default_context = {}, result_class = nil)
      @filters = filters.flatten.freeze
      @default_context = default_context.freeze
      @result_class = result_class || Hash
    end

    # Apply all filters in the pipeline to the given HTML.
    #
    # html    - A String containing HTML or a DocumentFragment object.
    # context - The context hash passed to each filter. See the Filter docs
    #           for more info on possible values. This object MUST NOT be modified
    #           in place by filters.  Use the Result for passing state back.
    # result  - The result Hash passed to each filter for modification.  This
    #           is where Filters store extracted information from the content.
    #
    # Returns the result Hash after being filtered by this Pipeline.  Contains an
    # :output key with the DocumentFragment or String HTML markup based on the
    # output of the last filter in the pipeline.
    def call(html, context = {}, result = nil)
      context = context.merge(@default_context).freeze
      result ||= @result_class.new
      result[:output] = @filters.inject(html) { |doc, filter| filter.call(doc, context, result) }
      result
    end

    # Like call but guarantee the value returned is a DocumentFragment.
    # Pipelines may return a DocumentFragment or a String. Callers that need a
    # DocumentFragment should use this method.
    def to_document(input, context = {}, result = nil)
      result = call(input, context, result)
      HTML::Pipeline.parse(result[:output])
    end

    # Like call but guarantee the value returned is a string of HTML markup.
    def to_html(input, context = {}, result = nil)
      result = call(input, context, result = nil)
      output = result[:output]
      if output.respond_to?(:to_html)
        output.to_html
      else
        output.to_s
      end
    end
  end
end
# frozen_string_literal: true

class HTMLPipeline
  class TextFilter < Filter
    attr_reader :text

    def initialize(text, context: {}, result: {})
      raise TypeError, "text cannot be HTML" if text.is_a?(DocumentFragment)

      # Ensure that this is always a string
      @text = text.respond_to?(:to_str) ? text.to_str : text.to_s
      super(context: context, result: result)
    end

    # Like call but guarantees that a string of HTML markup is returned.
    def self.process(input, context: {})
      output = call(input, context: context)
      if output.respond_to?(:to_html)
        output.to_html
      else
        output.to_s
      end
    end
  end
end

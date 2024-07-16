# frozen_string_literal: true

class HTMLPipeline
  class TextFilter < Filter
    attr_reader :text

    def initialize(context: {}, result: {})
      super
    end

    class << self
      def call(text, context: {}, result: {})
        raise TypeError, "text must be a String" unless text.is_a?(String)

        # Ensure that this is always a string
        text = text.respond_to?(:to_str) ? text.to_str : text.to_s
        new(context: context, result: result).call(text)
      end
    end
  end
end

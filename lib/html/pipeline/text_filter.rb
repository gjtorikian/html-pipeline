# frozen_string_literal: true

module HTML
  class Pipeline
    class TextFilter < Filter
      attr_reader :text

      def initialize(text, context: {}, result: {})
        raise TypeError, 'text cannot be HTML' if text.is_a?(DocumentFragment)

        # Ensure that this is always a string
        @text = text.respond_to?(:to_str) ? text.to_str : text.to_s
        super nil, context: context, result: result
      end
    end
  end
end

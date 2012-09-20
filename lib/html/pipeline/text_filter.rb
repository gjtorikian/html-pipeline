module HTML::Pipeline
  class TextFilter < Filter
    attr_reader :text

    def initialize(text, context = nil, result = nil)
      raise TypeError, "text cannot be HTML" if text.is_a?(DocumentFragment)
      # Ensure that this is always a string
      @text = text.try(:to_str) || text.to_s
      super nil, context, result
    end
  end
end
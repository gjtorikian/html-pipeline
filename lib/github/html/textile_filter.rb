module GitHub::HTML
  # HTML Filter that converts Textile text into HTML and converts into a
  # DocumentFragment. This is different from most filters in that it can take a
  # non-HTML as input. It must be used as the first filter in a pipeline.
  #
  # Context options:
  #   :autolink => false    Disable autolinking URLs
  #
  # This filter does not write any additional information to the context hash.
  #
  # NOTE This filter is provided for really old comments only. It probably
  # shouldn't be used for anything new.
  class TextileFilter < Filter
    def initialize(text, context={})
      raise TypeError, "text cannot be HTML" if text.is_a?(DocumentFragment)
      @text = text.to_s
      super nil, context
    end

    # Convert Textile to HTML and convert into a DocumentFragment.
    def call
      RedCloth.new(@text).to_html
    end
  end
end

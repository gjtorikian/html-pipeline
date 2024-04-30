# frozen_string_literal: true

require "selma"

class HTMLPipeline
  class NodeFilter < Filter
    attr_accessor :context

    def initialize(context: {}, result: {})
      super(context: context, result: {})
      send(:after_initialize) if respond_to?(:after_initialize)
    end

    # The String representation of the document.
    def html
      raise InvalidDocumentException if @html.nil? && @doc.nil?

      @html || doc.to_html
    end

    def reset!
      result = {} # rubocop:disable Lint/UselessAssignment
      send(:after_initialize) if respond_to?(:after_initialize)
    end

    class << self
      def call(html, context: {}, result: {})
        node_filter = new(context: context, result: result)
        Selma::Rewriter.new(sanitizer: nil, handlers: [node_filter]).rewrite(html)
      end
    end
  end
end

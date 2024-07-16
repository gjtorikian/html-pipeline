# frozen_string_literal: true

HTMLPipeline.require_dependency("rouge", "SyntaxHighlightFilter")

class HTMLPipeline
  class NodeFilter
    # HTML Filter that syntax highlights text inside code blocks.
    #
    # Context options:
    #
    #   :highlight => String represents the language to pick lexer. Defaults to empty string.
    #   :scope => String represents the class attribute adds to pre element after.
    #             Defaults to "highlight highlight-css" if highlights a css code block.
    #
    # This filter does not write any additional information to the context hash.
    class SyntaxHighlightFilter < NodeFilter
      def initialize(context: {}, result: {})
        super
        # TODO: test the optionality of this
        @formatter = context[:formatter] || Rouge::Formatters::HTML.new
      end

      SELECTOR = Selma::Selector.new(match_element: "pre", match_text_within: "pre")

      def selector
        SELECTOR
      end

      def handle_element(element)
        default = context[:highlight]&.to_s
        @lang = element["lang"] || default

        scope = context.fetch(:scope, "highlight")

        element["class"] = "#{scope} #{scope}-#{@lang}" if include_lang?
      end

      def handle_text_chunk(text)
        return if @lang.nil?
        return if (lexer = lexer_for(@lang)).nil?

        content = text.to_s

        text.replace(highlight_with_timeout_handling(content, lexer), as: :html)
      end

      def highlight_with_timeout_handling(text, lexer)
        Rouge.highlight(text, lexer, @formatter)
      rescue Timeout::Error => _e
        text
      end

      def lexer_for(lang)
        Rouge::Lexer.find(lang)
      end

      def include_lang?
        !@lang.nil? && !@lang.empty?
      end
    end
  end
end

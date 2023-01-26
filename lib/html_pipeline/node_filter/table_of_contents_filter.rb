# frozen_string_literal: true

class HTMLPipeline
  class NodeFilter
    # Generates a Table of Contents: an array of hashes containing:
    # * `href`: the relative link to the header
    # * `text`: the text of the header

    # Examples
    #
    #  TocPipeline =
    #    HTMLPipeline.new [
    #      HTMLPipeline::TableOfContentsFilter
    #    ]
    #  # => #<HTMLPipeline:0x007fc13c4528d8...>
    #  orig = %(<h1>Ice cube</h1><p>is not for the pop chart</p>)
    #  # => "<h1>Ice cube</h1><p>is not for the pop chart</p>"
    #  result = {}
    #  # => {}
    #  TocPipeline.call(orig, {}, result)
    #  # => {:toc=> ...}
    #  result[:toc]
    #  # => "{:href=>"#ice-cube", :text=>"Ice cube"}"
    #  result[:output].to_s
    #  # => "<h1>\n<a id=\"ice-cube\" class=\"anchor\" href=\"#ice-cube\">..."
    class TableOfContentsFilter < NodeFilter
      SELECTOR = Selma::Selector.new(
        match_element: "h1 a[href], h2 a[href], h3 a[href], h4 a[href], h5 a[href], h6 a[href]",
        match_text_within: "h1, h2, h3, h4, h5, h6",
      )

      def selector
        SELECTOR
      end

      # The icon that will be placed next to an anchored rendered markdown header
      def anchor_html
        @context[:anchor_html] || %(<span aria-hidden="true" class="anchor"></span>)
      end

      # The class that will be attached on the anchored rendered markdown header
      def classes
        context[:classes] || "anchor"
      end

      def after_initialize
        result[:toc] = []
      end

      def handle_element(element)
        header_href = element["href"]

        return unless header_href.start_with?("#")

        header_id = header_href[1..-1]

        element["id"] = header_id
        element["class"] = classes

        element.set_inner_content(anchor_html, as: :html)

        result[:toc] << { href: header_href }
      end

      def handle_text_chunk(text)
        result[:toc].last[:text] = text.to_s
      end
    end
  end
end

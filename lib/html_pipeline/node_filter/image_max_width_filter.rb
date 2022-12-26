# frozen_string_literal: true

class HTMLPipeline
  class NodeFilter
    # This filter rewrites image tags with a max-width inline style and also wraps
    # the image in an <a> tag that causes the full size image to be opened in a
    # new tab.
    #
    # The max-width inline styles are especially useful in HTML email which
    # don't use a global stylesheets.
    class ImageMaxWidthFilter < NodeFilter
      SELECTOR = Selma::Selector.new(match_element: "img")

      def selector
        SELECTOR
      end

      def handle_element(element)
        # Skip if there's already a style attribute. Not sure how this
        # would happen but we can reconsider it in the future.
        return if element["style"]

        # Bail out if src doesn't look like a valid http url. trying to avoid weird
        # js injection via javascript: urls.
        return if /\Ajavascript/i.match?(element["src"].to_s.strip)

        element["style"] = "max-width:100%;"

        link_image(element) unless has_ancestor?(element, "a")
      end

      def link_image(element)
        link_start = %(<a target="_blank" href="#{element["src"]}">)
        element.before(link_start, as: :html)
        link_end = "</a>"
        element.after(link_end, as: :html)
      end
    end
  end
end

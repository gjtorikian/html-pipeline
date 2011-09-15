module GitHub::HTML
  # HTML Filter for auto_linking urls.
  class AutolinkFilter < Filter
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper

    def call
      html = doc.to_html
      html = auto_link(html, :link => :urls)
      parse_html(html)
    end
  end
end

module GitHub::HTML
  # HTML Filter for auto_linking urls.
  class AutolinkFilter < Filter
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper

    def call
      doc.search('text()').each do |node|
        content = node.to_html
        next if node.ancestors('pre, code, a').any?
        html = auto_link(content, :link => :urls)
        next if html == content
        node.replace(html)
      end
      doc
    end
  end
end

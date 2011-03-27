module GitHub::HTML
  # HTML Filter for auto_linking.
  class AutolinkFilter < Filter
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper

    def call
      doc.search('text()').each do |node|
        content = node.to_html
        next if !content.include?('http')
        next if node.ancestors('pre, code').any?
        html = auto_link(content)
        next if html == content
        node.replace(html)
      end
      doc
    end
  end
end

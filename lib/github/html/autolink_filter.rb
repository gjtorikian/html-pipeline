require 'rinku'

module GitHub::HTML
  # HTML Filter for auto_linking urls in HTML.
  class AutolinkFilter < Filter
    def call
      return doc if context[:autolink] == false
      html = doc.to_html
      html = Rinku.auto_link(html, :urls, nil, %w[a script kbd])
      @doc = parse_html(html)
    end
  end
end

require 'rinku'

module GitHub::HTML
  # HTML Filter for auto_linking urls in HTML.
  class AutolinkFilter < Filter
    def call
      return html if context[:autolink] == false
      Rinku.auto_link(html, :urls, nil, %w[a script kbd])
    end
  end
end

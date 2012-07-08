require 'rinku'

module GitHub::HTML
  # HTML Filter for auto_linking urls in HTML.
  class AutolinkFilter < Filter
    def call
      return html if context[:autolink] == false
      flags = 0

      if GitHub.enterprise?
        flags |= Rinku::AUTOLINK_SHORT_DOMAINS
      end

      Rinku.auto_link(html, :urls, nil, %w[a script kbd pre code], flags)
    end
  end
end

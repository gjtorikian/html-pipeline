require 'rinku'

module HTML::Pipeline
  # HTML Filter for auto_linking urls in HTML.
  #
  # Context options:
  #   :autolink - boolean whether to autolink urls
  #   :flags    - additional Rinku flags. See https://github.com/vmg/rinku
  #
  # This filter does not write additional information to the context.
  class AutolinkFilter < Filter
    def call
      return html if context[:autolink] == false
      flags = 0
      flags |= context[:flags] if context[:flags]

      Rinku.auto_link(html, :urls, nil, %w[a script kbd pre code], flags)
    end
  end
end

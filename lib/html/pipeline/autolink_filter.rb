require 'rinku'

module HTML
  class Pipeline
    # HTML Filter for auto_linking urls in HTML.
    #
    # Context options:
    #   :autolink  - boolean whether to autolink urls
    #   :skip_tags - HTML tags inside which autolinking will be skipped.
    #                See Rinku.skip_tags
    #   :flags     - additional Rinku flags. See https://github.com/vmg/rinku
    #
    # This filter does not write additional information to the context.
    class AutolinkFilter < Filter
      def call
        return html if context[:autolink] == false

        skip_tags = context[:skip_tags]
        flags = 0
        flags |= context[:flags] if context[:flags]

        Rinku.auto_link(html, :urls, nil, skip_tags, flags)
      end
    end
  end
end

require 'set'

module HTML
  class Pipeline
    # HTML filter that replaces #mention mentions with links to Github issue. Mentions within <pre>,
    # <code>, <style> and <a> elements are ignored.
    #
    # Context options:
    #   :base_url - Used to construct links to issue page for each mention.
    #   :issueid_pattern - Used to provide a custom regular expression to
    #                       identify issue ids
    #
    class IssueMentionFilter < Filter
      # Public: Find issue #mention in text.  See
      # IssueMentionFilter#mention_link_filter.
      #
      #   IssueMentionFilter.mentioned_issues_in(text) do |match, issueid|
      #     "<a href=...>#{issueid}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the String issueid.  The yield's return replaces the match in
      # the original text.
      #
      # Returns a String replaced with the return of the block.
      def self.mentioned_issues_in(text, issueid_pattern=IssueidPattern)
        text.gsub MentionPatterns[issueid_pattern] do |match|
          issueid = $1
          yield match, issueid
        end
      end


      # Hash that contains all of the mention patterns used by the pipeline
      MentionPatterns = Hash.new do |hash, key|
        hash[key] = /
          (?:^|\W)                    # beginning of string or non-word char
          \#((?>#{key}))              # #issueid
          (?!\/)                      # without a trailing slash
          (?=
            \.+[ \t\W]|               # dots followed by space or non-word character
            \.+$|                     # dots at end of line
            [^0-9a-zA-Z_.]|           # non-word character except dot
            $                         # end of line
          )
        /ix
      end

      # Default pattern used to extract issueid from text. The value can be
      # overriden by providing the issueid_pattern variable in the context.
      IssueidPattern = /[0-9][0-9-]*/

      # Don't look for mentions in text nodes that are children of these elements
      IGNORE_PARENTS = %w(pre code a style).to_set

      def call
        result[:mentioned_issueids] ||= []

        doc.search('text()').each do |node|
          content = node.to_html
          next if !content.include?('#')
          next if has_ancestor?(node, IGNORE_PARENTS)
          html = mention_link_filter(content, base_url, issueid_pattern)
          next if html == content
          node.replace(html)
        end
        doc
      end

      def issueid_pattern
        context[:issueid_pattern] || IssueidPattern
      end

      # Replace issue #mentions in text with links to the mentioned
      # issue's page.
      #
      # text      - String text to replace #mention issueids in.
      # base_url  - The base URL used to construct issue page URLs.
      # issueid_pattern  - Regular expression used to identify issueid in
      #                     text
      #
      # Returns a string with #issueid replaced with links. All links have a
      # 'issue-mention' class name attached for styling.
      def mention_link_filter(text, base_url='/', issueid_pattern)
        self.class.mentioned_issues_in(text, issueid_pattern) do |match, issueid|
          link = link_to_mentioned_issue(issueid)
          link ? match.sub("\##{issueid}", link) : match
        end
      end

      def link_to_mentioned_issue(issueid)
        result[:mentioned_issueids] |= [issueid]

        url = base_url.dup
        url << "/" unless url =~ /[\/~]\z/

        "<a href='#{url << issueid}' class='issue-mention'>" +
        "\##{issueid}" +
        "</a>"
      end
    end
  end
end

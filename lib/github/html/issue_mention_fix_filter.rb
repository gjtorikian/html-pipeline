module GitHub
  module HTML
    # HTML Filter for replacing issue references like closed #35, fixes #36, or
    # #37 with links to issues. Also collects a list of referenced issues and
    # makes them available in the context hash.
    #
    # Context options:
    #   :repository         - Repository used to look up issues.
    #   :issues_references  - A Hash that recieves IssueReference objects. Hash
    #                         keys are issue numbers and values are an
    #                         IssueReference. You can use IssueReference#closed?
    #                         to determine if the reference was prefixed with
    #                         (close[sd]|fixe[sd]).
    #
    class IssueMentionFixFilter < Filter
      MATCHER = /(close[sd]?|fixe[sd])? (gh-|#)(\d+)\b/i

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if !(content.include?('#') || content.include?('gh-')) # perf
          next if node.ancestors('pre, code, a').any?                 # <- slow

          html = replace_issue_references(content)

          next if html == content

          node.replace(html)
        end
      end

      # Hash of issue_number => IssueReference elements that goes into the
      # context hash so that callers can find the issue referenced.
      def issue_references
        context[:issue_references] ||= {}
      end

      # Find occurrences of issue references in HTML text and replace with links
      # to the issue. All referenced issues are recorded in the
      # :mentioned_issues context hash value.
      #
      # text - String HTML text. This will never contain markup. It's always the
      #        HTML encoded text node value.
      #
      # Returns nothing
      def replace_issue_references(text)
        text.gsub(MATCHER) do |match|
          word, pound, number = $1, $2, $3.to_i

          if reference = issue_references[number]
            issue = reference.issue
          elsif issue = find_issue(number)
            reference = IssueReference.new(issue, word.to_s)
            issue_references[number] = reference
          end

          if issue
            "<a href=\"#{issue_url(issue)}\">#{match}</a>"
          else
            match
          end
        end
      end

      # Find an issue in the current repository context.
      def find_issue(number)
        repository.issues.find_by_number(number) if repository
      end

      private

      def repository
        @context[:repository] ||
          raise(Error, "context must include the repository")
      end
    end
  end
end

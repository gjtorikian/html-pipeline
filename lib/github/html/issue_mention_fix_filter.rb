module GitHub
  module HTML
    class IssueMentionFixFilter < Filter
      class Error < StandardError; end

      WORDS = %w[close closes closed fix fixes fixed]
      REGEX = /(#{Regexp.union(WORDS)}) (gh-|\#)(\d+)\b/i

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if !WORDS.any? { |w| content.include?(w) }
          next if node.ancestors('pre, code, a').any?

          html = replace_issue_mention_fix(content)

          next if html == content

          node.replace(html)
        end
      end

      private

      def replace_issue_mention_fix(text)
        text.gsub(REGEX) do |text|
          number = Integer($3)

          if issue = find_issue(number)
            "<a href=\"#{issue_url(issue)}\">#{text}</a>"
          else
            text
          end
        end
      end

      def find_issue(number)
        repository.issues.find_by_number(number)
      end

      def issue_url(issue)
        File.join(base_url, repository.name_with_owner, "issues",
          issue.number.to_s)
      end

      def base_url
        @context[:base_url] || GitHub::SSLHost
      end

      def repository
        @context[:repository] ||
          raise(Error, "context must include the repository")
      end
    end
  end
end

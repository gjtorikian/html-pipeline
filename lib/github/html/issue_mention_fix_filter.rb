module GitHub
  module HTML
    class IssueMentionFixFilter < Filter
      class Error < StandardError; end

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if !WORDS.any? { |w| content.include?(w) }
          next if node.ancestors('pre, code, a').any?

          html = IssueReference.auto_link(repository, text, base_url)

          next if html == content

          node.replace(html)
        end
      end

      private

      def repository
        @context[:repository] ||
          raise(Error, "context must include the repository")
      end
    end
  end
end

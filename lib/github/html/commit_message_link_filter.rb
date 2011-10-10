module GitHub
  module HTML
    class CommitMessageLinkFilter < Filter
      def call
        return doc unless url = context.delete(:url)
        doc.child.children.each do |node|
          next unless node.text?
          node.replace("<a class=\"message\" href=\"#{url}\">#{node.to_s}</a>")
        end
        doc
      end
    end
  end
end


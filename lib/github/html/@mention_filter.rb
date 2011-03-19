module GitHub::HTML

  # HTML filter that replaces @user mentions with links. Mentions within <pre>,
  # <code>, and <a> elements are ignored.
  class MentionFilter < Filter
    include GitHub::Mentionable

    def call
      doc.search('text()').each do |node|
        next if !node.content.include?('@')
        next if node.ancestors('pre, code, a').any?
        html = mention_link_filter(node.content, base_url)
        node.replace(html) if html != node.content
      end
    end
  end
end

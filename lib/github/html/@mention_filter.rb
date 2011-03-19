module GitHub::HTML

  # HTML filter that replaces @user mentions with links. Mentions within <pre>,
  # <code>, and <a> elements are ignored. Mentions that reference users that do
  # not exist are ignored.
  #
  # Context options:
  #   :base_url - Used to construct links to user profile pages for each
  #               mention.
  #
  # This filter does not write additional information to the context (yet).
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

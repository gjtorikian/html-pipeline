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
        content = node.to_html
        next if !content.include?('@')
        next if node.ancestors('pre, code, a').any?
        html = mention_link_filter(content, base_url)
        next if html == content
        node.replace(html)
      end
    end
  end
end

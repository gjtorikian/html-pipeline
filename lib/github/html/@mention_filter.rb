module GitHub::HTML
  # HTML filter that replaces @user mentions with links. Mentions within <pre>,
  # <code>, and <a> elements are ignored. Mentions that reference users that do
  # not exist are ignored.
  #
  # Context options:
  #   :base_url - Used to construct links to user profile pages for each
  #               mention.
  #
  # The following keys are written to the context hash:
  #   :mentioned_users - An array of User objects that were mentioned.
  #
  class MentionFilter < Filter
    MentionPattern = /(?:^|\W)@([a-z0-9][a-z0-9-]*)(?=\W|$)/i

    def call
      mentioned_users.clear
      text_nodes.each do |node|
        content = node.to_html
        next if !content.include?('@')
        html = mention_link_filter(content, base_url)
        next if html == content
        node.replace(html)
      end
      mentioned_users.uniq!
      doc
    end

    # List of User objects that were mentioned in the document. This is
    # available in the context hash as :mentioned_users.
    def mentioned_users
      context[:mentioned_users] ||= []
    end

    # Replace user @mentions in text with links to the mentioned user's
    # profile page.
    #
    # text      - String text to replace @mention usernames in.
    # base_url  - The base URL used to construct user profile URLs.
    #
    # Returns a string with @mentions replaced with links. All links have a
    # 'user-mention' class name attached for styling.
    def mention_link_filter(text, base_url='/')
      text.gsub MentionPattern do |match|
        login = $1
        user = User.cached_by_login($1)
        next match if user.nil?
        next match if !mentionable?(user)

        mentioned_users << user
        url = File.join(base_url, user.login)
        link =
          "<a href='#{url}' class='user-mention'>" +
          "@#{user.login}" +
          "</a>"
        match.sub("@#{login}", link)
      end
    end

    # Determine if a user is mentionable in the current context.
    #
    #   user - The User object to check
    #
    # Returns true when the user may be mentioned
    def mentionable?(user)
      if repository
        repository.pullable_by?(user)
      else
        true
      end
    end
  end
end

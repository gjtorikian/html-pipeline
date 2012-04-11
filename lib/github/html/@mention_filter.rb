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
    MentionPattern = /
      (?:^|\W)                   # beginning of string or non-word char
      @([a-z0-9][a-z0-9-]*)      # @username
      (?=
        \.[ \t]|                 # dot followed by space
        \.$|                     # dot at end of line
        [^0-9a-zA-Z_.]|          # non-word character except dot
        $                        # end of line
      )
    /ix

    def call
      mentioned_users.clear
      doc.search('text()').each do |node|
        content = node.to_html
        next if !content.include?('@')
        next if (node.css_path.split & %w(pre code a)).any?
        next if node.ancestors('.user-mention').any?
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
        if login =~ /^mention(s|ed|)$/
          link = link_to_mention_info(login)
        elsif user = User.find_by_login(login)
          mentioned_users << user
          link = link_to_mentioned_user(user)
        else
          next match
        end
        match.sub("@#{login}", link)
      end
    end

    def link_to_mention_info(text)
      "<a href='https://github.com/blog/821' class='user-mention'>" +
      "@#{text}" +
      "</a>".html_safe
    end

    def link_to_mentioned_user(user)
      url = File.join(base_url, user.login)
      "<a href='#{url}' class='user-mention'>" +
      "@#{user.login}" +
      "</a>"
    end
  end
end

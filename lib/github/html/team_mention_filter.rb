module GitHub::HTML
  # HTML filter that replaces @enterprise/team mentions with TODO. Mentions within <pre>,
  # <code>, and <a> elements are ignored. Mentions that reference orgs or teams that do
  # not exist are ignored.
  #
  # Context options:
  #   :base_url - Used to construct links to user profile pages for each
  #               mention.
  #
  # The following keys are written to the context hash:
  #   :mentioned_teams - An array of Team objects that were mentioned.
  #
  class TeamMentionFilter < Filter
    # Public: Find team mentions in text -- team mentions follow the syntax
    # @org-name/team-slug. See MentionFilter#mention_team_filter.
    #
    #   MentionFilter.mentioned_teams_in(text) do |match, org, team|
    #     "<a href=...>#{org}/#{team}</a>"
    #   end
    #
    # text - String text to search.
    #
    # Yields the String match, the String org name, and the string team name.
    # The yield's return replaces the match in the original text.
    #
    # Returns a String replaced with the return of the block.
    def self.mentioned_teams_in(text)
      text.gsub MentionPattern do |match|
        org = $1
        team = $2
        yield match, org, team
      end
    end

    MentionPattern = /
      (?:^|\W)                   # beginning of string or non-word char
      @([a-z0-9][a-z0-9-]+)      # @organization
        \/                       # dividing slash
        ([a-z0-9][a-z0-9-]+)     # team
      (?=
        \.[ \t]|                 # dot followed by space
        \.$|                     # dot at end of line
        [^0-9a-zA-Z_.]|          # non-word character except dot
        $                        # end of line
      )
    /ix

    def call
      mentioned_teams.clear
      doc.search('text()').each do |node|
        content = node.to_html
        next if !content.include?('@')
        next if has_ancestor?(node, %w(pre code a))
        html = mention_team_filter(content, base_url)
        next if html == content
        node.replace(html)
      end
      mentioned_teams.uniq!
      doc
    end

    # List of Team objects that were mentioned in the document. This is
    # available in the context hash as :mentioned_teams.
    def mentioned_teams
      context[:mentioned_teams] ||= []
    end

    # Replace team @mentions in text with a span showing what users are in the team.
    #
    # text      - String text to replace @mention team names in.
    # base_url  - The base URL used to construct user profile URLs.
    #
    # Returns a string with the replacements made. All links have a
    # 'team-mention' class name attached for styling.
    def mention_team_filter(text, base_url='/')
      self.class.mentioned_teams_in(text) do |match, org_name, team_name|
        team = Team.find_by_org_name_and_slug(org_name, team_name)
        if team
          mentioned_teams << team
          html = mentioned_team_html(team)
          match.sub(match.strip, html)
        else
          match
        end
      end
    end

    # Replace with a span for styling (for now)
    def mentioned_team_html(team)
      tooltip = "team members: #{team.users.map(&:login).to_sentence}"
      html = %|<span class='team-mention tooltipped downwards' title="#{tooltip}">@#{team.organization.login}/#{team.slug}</span>|
    end
  end
end

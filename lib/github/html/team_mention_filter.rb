module GitHub::HTML
  # HTML filter that replaces @enterprise/team mentions with TODO. Mentions within <pre>,
  # <code>, and <a> elements are ignored. Mentions that reference orgs or teams that do
  # not exist are ignored.
  #
  # Context options:
  #   N/A
  #
  # The following keys are written to the Result:
  #   :mentioned_teams - An array of Team objects that were mentioned.
  #
  class TeamMentionFilter < Filter
    # Public: Find team mentions in text -- team mentions follow the syntax
    # @org-name/team-slug. See TeamMentionFilter#mention_team_filter.
    #
    #   TeamMentionFilter.mentioned_teams_in(text) do |match, org, team|
    #     "<a href=...>#{org}/#{team}</a>"
    #   end
    #
    # text - String text to search.
    #
    # Yields the String match, the String org name, and the String team name.
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

    # Don't look for mentions in text nodes that are children of these elements
    IGNORE_PARENTS = %w(pre code a).to_set

    def call
      return doc unless current_user
      mentioned_teams.clear
      doc.search('text()').each do |node|
        content = node.to_html
        next if !content.include?('@')
        next if has_ancestor?(node, IGNORE_PARENTS)
        html = mention_team_filter(content)
        next if html == content
        node.replace(html)
      end
      mentioned_teams.uniq!
      doc
    end

    # List of Team objects that were mentioned in the document. This is
    # available in the context hash as :mentioned_teams.
    def mentioned_teams
      result[:mentioned_teams] ||= []
    end

    # Replace team @mentions in text with a span showing what users are in the team.
    #
    # text      - String text to replace @mention team names in.
    #
    # Returns a string with the replacements made. All links have a
    # 'team-mention' class name attached for styling.
    def mention_team_filter(text)
      self.class.mentioned_teams_in(text) do |match, org_name, team_name|
        if team = find_team(org_name, team_name)
          mentioned_teams << team
          html = mentioned_team_html(team)
          match.sub(match.strip, html)
        else
          match
        end
      end
    end

    # Internal: find the team, properly scoped for security
    def find_team(org_name, team_name)
      return nil unless repository
      teams = current_user.teams_for(repository.organization)
      p "teams", teams
      teams.find_by_org_name_and_slug(org_name, team_name) if teams.any?
    end

    # Replace with a span for the tooltip
    def mentioned_team_html(team)
      if context[:formatter] == :email
        %|<span style="font-weight:bold">@#{team.organization.login}/#{team.slug}</span>|
      else
        tooltip = "team members: #{team.users.map(&:login).to_sentence}"
        %|<span class='team-mention tooltipped downwards' title="#{tooltip}">@#{team.organization.login}/#{team.slug}</span>|
      end
    end
  end
end

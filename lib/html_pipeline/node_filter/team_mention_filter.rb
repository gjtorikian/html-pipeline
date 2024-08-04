# frozen_string_literal: true

require "set"

class HTMLPipeline
  class NodeFilter
    # HTML filter that replaces @org/team mentions with links. Mentions within
    # <pre>, <code>, <a>, <style>, and <script> elements are ignored.
    #
    # Context options:
    #   :base_url - Used to construct links to team profile pages for each
    #               mention.
    #   :team_pattern - Used to provide a custom regular expression to
    #                       identify team names
    #
    class TeamMentionFilter < NodeFilter
      class << self
        # Public: Find @org/team mentions in text.  See
        # TeamMentionFilter#team_mention_link_filter.
        #
        #   TeamMentionFilter.mentioned_teams_in(text) do |match, org, team|
        #     "<a href=...>#{team}</a>"
        #   end
        #
        # text - String text to search.
        #
        # Yields the String match, org name, and team name.  The yield's
        # return replaces the match in the original text.
        #
        # Returns a String replaced with the return of the block.
        def mentioned_teams_in(text, team_pattern = TEAM_PATTERN)
          text.gsub(team_pattern) do |match|
            org = Regexp.last_match(1)
            team = Regexp.last_match(2)
            yield match, org, team
          end
        end
      end

      # Default pattern used to extract team names from text. The value can be
      # overridden by providing the team_pattern variable in the context. To
      # properly link the mention, should be in the format of /@(1)\/(2)/.
      TEAM_PATTERN = %r{
        (?<=^|\W)                  # beginning of string or non-word char
        @([a-z0-9][a-z0-9-]*)      # @organization
          (?:/|&\#47;?)             # dividing slash
          ([a-z0-9][a-z0-9\-_]*)   # team
          \b
      }ix

      # Don't look for mentions in text nodes that are children of these elements
      IGNORE_PARENTS = ["pre", "code", "a", "style", "script"]

      SELECTOR = Selma::Selector.new(match_text_within: "*", ignore_text_within: IGNORE_PARENTS)

      def after_initialize
        result[:mentioned_teams] = []
      end

      def selector
        SELECTOR
      end

      def handle_text_chunk(text)
        content = text.to_s
        return unless content.include?("@")

        text.replace(mention_link_filter(content, base_url: base_url, team_pattern: team_pattern), as: :html)
      end

      def team_pattern
        context[:team_pattern] || TEAM_PATTERN
      end

      # Replace @org/team mentions in text with links to the mentioned team's
      # page.
      #
      # text      - String text to replace @mention team names in.
      # base_url  - The base URL used to construct team page URLs.
      # team_pattern  - Regular expression used to identify teams in text
      #
      # Returns a string with @team mentions replaced with links. All links have a
      # 'team-mention' class name attached for styling.
      def mention_link_filter(text, base_url: "/", team_pattern: TEAM_PATTERN)
        self.class.mentioned_teams_in(text, team_pattern) do |match, org, team|
          link = link_to_mentioned_team(base_url, org, team)
          seperator = %r{/|&\#47;?}

          link ? match.sub(/@#{org}#{seperator}#{team}/, link) : match
        end
      end

      def link_to_mentioned_team(base_url, org, team)
        result[:mentioned_teams] |= [team]

        url = base_url.dup
        excluded_prefixes = %r{[/(?:~|@]\z}
        url << "/" unless excluded_prefixes.match?(url)

        "<a href=\"#{url << org}/#{team}\" class=\"team-mention\">" \
          "@#{org}/#{team}" \
          "</a>"
      end
    end
  end
end

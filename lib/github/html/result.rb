module GitHub::HTML
  # A Struct for results passed back from the Pipelines
  # This allows us to have some explicit-ness around the types of things that
  # pipelines add to the repsonse.
  #
  # Members of the Result:
  #   output - the DocumentFragment or String result of the Pipeline
  #   mentioned_users - see GitHub::HTML::MentionFilter
  #   mentioned_teams - see GitHub::HTML::TeamMentionFilter
  #   commits - see GitHub::HTML::CommitMentionFilter
  #   commits_count - see GitHub::HTML::CommitMentionFilter
  #   issues - see GitHub::HTML::IssueMentionFilter
  class Result < Struct.new(:output,
      :mentioned_users,
      :mentioned_teams,
      :commits, :commits_count,
      :issues
    )

    def to_s
      output.to_s
    end
  end
end

# typed: strict
# frozen_string_literal: true

module Spoom
  class Timeline
    #: (Context context, Time from, Time to) -> void
    def initialize(context, from, to)
      @context = context
      @from = from
      @to = to
    end

    # Return one commit for each month between `from` and `to`
    #: -> Array[Git::Commit]
    def ticks
      commits_for_dates(months)
    end

    # Return all months between `from` and `to`
    #: -> Array[Time]
    def months
      d = Date.new(@from.year, @from.month, 1)
      to = Date.new(@to.year, @to.month, 1)
      res = [d.to_time]
      while d < to
        d = d.next_month
        res << d.to_time
      end
      res
    end

    # Return one commit for each date in `dates`
    #: (Array[Time] dates) -> Array[Git::Commit]
    def commits_for_dates(dates)
      dates.map do |t|
        result = @context.git_log(
          "--since='#{t}'",
          "--until='#{t.to_date.next_month}'",
          "--format='format:%h %at'",
          "--author-date-order",
          "-1",
        )
        next if result.out.empty?

        Spoom::Git::Commit.parse_line(result.out.strip)
      end.compact.uniq(&:sha)
    end
  end
end

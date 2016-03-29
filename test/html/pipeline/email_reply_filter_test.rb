require "test_helper"

EmailReplyFilter = HTML::Pipeline::EmailReplyFilter

class HTML::Pipeline::EmailReplyFilterTest < Minitest::Test
  def test_hides_email_addresses
    filter = EmailReplyFilter.new(<<-EMAIL, :highlight => "coffeescript")
Hey, don't send email addresses in comments. They aren't filtered.

> On Mar 5, 2016, at 08:05, Hacker J. Hackerson <example@example.com> wrote:
>
> Sup. alreadyleaked@example.com
>
> —
> Reply to this email directly or view it on GitHub.
>
EMAIL

    doc = filter.call
    refute_match %r(example@example.com), doc.to_s
    assert_match %r(alreadyleaked@example.com), doc.to_s
  end
end

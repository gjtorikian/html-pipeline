require "test_helper"

EmailReplyFilter = HTML::Pipeline::EmailReplyFilter

class HTML::Pipeline::EmailReplyFilterTest < Minitest::Test
  def setup
    @body = <<-EMAIL
Hey, don't send email addresses in comments. They aren't filtered.

> On Mar 5, 2016, at 08:05, Boaty McBoatface <boatymcboatface@example.com> wrote:
>
> Sup. alreadyleaked@example.com
>
> —
> Reply to this email directly or view it on GitHub.
EMAIL
  end

  def test_doesnt_hide_by_default
    filter = EmailReplyFilter.new(@body)
    doc = filter.call.to_s
    assert_match %r(alreadyleaked@example.com), doc
    assert_match %r(boatymcboatface@example.com), doc
  end

  def test_hides_email_addresses_when_configured
    filter = EmailReplyFilter.new(@body, :hide_quoted_email_addresses => true)
    doc = filter.call.to_s
    refute_match %r(boatymcboatface@example.com), doc
    refute_match %r(alreadyleaked@example.com), doc
  end
end

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

  def test_preserves_non_email_content_while_filtering
    str = <<-EMAIL
> Thank you! I have some thoughts on this pull request.
>
>  *  acme provides cmake and a wrapper for it. Please use '$(TARGET)-cmake' instead of cmake -DCMAKE_TOOLCHAIN_FILE='$(CMAKE_TOOLCHAIN_FILE)' -DCMAKE_BUILD_TYPE=Release.

Okay -- I'm afraid I just blindly copied the eigen3.mk file, since that's a library I'm familiar with :-)

>  *  Do you need -DCMAKE_SYSTEM_PROCESSOR=x86?

Yes, this is a bit dumb, but vc checks for that (or amd) to determine that it's not being built on ARM.

--
Boaty McBoatface | http://example.org
EMAIL

    filter = EmailReplyFilter.new(str, :hide_quoted_email_addresses => true)
    doc = filter.call.to_s

    expected = <<-EXPECTED
<div class="email-quoted-reply"> Thank you! I have some thoughts on this pull request.

  *  acme provides cmake and a wrapper for it. Please use &#39;$(TARGET)-cmake&#39; instead of cmake -DCMAKE_TOOLCHAIN_FILE=&#39;$(CMAKE_TOOLCHAIN_FILE)&#39; -DCMAKE_BUILD_TYPE=Release.</div>
<div class="email-fragment">Okay -- I&#39;m afraid I just blindly copied the eigen3.mk file, since that&#39;s a library I&#39;m familiar with :-)</div>
<div class="email-quoted-reply">  *  Do you need -DCMAKE_SYSTEM_PROCESSOR=x86?</div>
<div class="email-fragment">Yes, this is a bit dumb, but vc checks for that (or amd) to determine that it&#39;s not being built on ARM.</div>
<span class="email-hidden-toggle"><a href="#">&hellip;</a></span><div class="email-hidden-reply" style="display:none"><div class="email-signature-reply">--
Boaty McBoatface | http:&#47;&#47;example.org</div>
</div>
EXPECTED

    assert_equal(expected.chomp, doc)
  end
end

require "ostruct"
require "digest"
require "cgi"
require "test_helper"

class HTML::Pipeline::GravatarFilterTest < Test::Unit::TestCase
  GravatarFilter = HTML::Pipeline::GravatarFilter

  def setup
    @email = "user@example.com"
    @email_hash = Digest::MD5.hexdigest(@email)
  end

  def link
    src = "https://www.gravatar.com/avatar/#{@email_hash}?s=40&amp;r=g"
    "<a href=\"/kneath\" class=\"user-avatar\">" +
    "<img title=\"kneath\" alt=\"kneath\" src=\"#{src}\" width=\"40\" height=\"40\">" +
    "</a>"
  end

  def service
    service = OpenStruct.new(:email => @email)
    def service.username_to_email(username)
      email
    end
    service
  end

  def filter(html, context={})
    context = { :avatar_service => service }.merge(context)
    GravatarFilter.call(html, context)
  end

  def test_required_context_validation
    exception = assert_raise(ArgumentError) {
      GravatarFilter.call("<p>$jch$</p>", {})
    }
    assert_match /:avatar_service/, exception.message
  end

  def test_required_avatar_service_implementation
    exception = assert_raise(GravatarFilter::InvalidGravatarServiceError) {
      GravatarFilter.call("<p>$jch$</p>", { :avatar_service => Object.new })
    }
    assert_equal "GravatarFilter avatar service must implement `username_to_email'", exception.message
  end

  def test_filtering_a_documentfragment
    body = "<p>$kneath$: check it out.</p>"
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)
    res  = filter(doc)
    assert_same doc, res
    assert_equal "<p>#{link}: check it out.</p>", res.to_html
  end

  def test_filtering_plain_text
    body = "<p>$kneath$: check it out.</p>"
    res  = filter(body)
    assert_equal "<p>#{link}: check it out.</p>", res.to_html
  end

  def test_not_replacing_avatars_in_pre_tags
    body = "<pre>$kneath$: okay</pre>"
    assert_equal body, filter(body).to_html
  end

  def test_not_replacing_avatars_in_code_tags
    body = "<p><code>$kneath$:</code> okay</p>"
    assert_equal body, filter(body).to_html
  end

  def test_not_replacing_avatars_in_links
    body = "<p><a>$kneath$</a> okay</p>"
    assert_equal body, filter(body).to_html
  end

  def test_entity_encoding_and_whatnot
    body = "<p>$&#x6b;neath$ what's up</p>"
    assert_equal "<p>#{link} what's up</p>", filter(body).to_html
  end

  def test_html_injection
    body = "<p>$kneath$ &lt;script>alert(0)&lt;/script></p>"
    assert_equal "<p>#{link} &lt;script&gt;alert(0)&lt;/script&gt;</p>",
      filter(body).to_html
  end

  def test_context_gravatar_rating
    body = "<p>$kneath$: check it out.</p>"
    res  = filter(body, :gravatar_rating => "g")
    assert_equal "<p>#{link}: check it out.</p>", res.to_html
  end

  def test_context_gravatar_size
    body = "<p>$kneath$: check it out.</p>"
    res  = filter(body, :gravatar_size => "40")
    assert_equal "<p>#{link}: check it out.</p>", res.to_html
  end

  def test_context_avatar_delimiter
    body = "<p>$kneath$: check it out.</p>"
    res  = filter(body, :avatar_delimiter => "$")
    assert_equal "<p>#{link}: check it out.</p>", res.to_html
  end

  def test_context_avatar_pattern
    body = "<p>$kneath$: check it out.</p>"
    context = {
      :avatar_delimiter => "$",
      :avatar_pattern => /\$((?>[a-z0-9][a-z0-9-]*))\$/i
    }
    res  = filter(body, context)
    assert_equal "<p>#{link}: check it out.</p>", res.to_html
  end

  def test_context_gravatar_default_image
    default_image = "http://www.gravatar.com/avatar/00000000000000000000000000000000"
    gravatar = "https://www.gravatar.com/avatar/#{@email_hash}?s=40&amp;r=g&amp;d=#{CGI.escape(default_image)}"
    link = "<a href=\"/kneath\" class=\"user-avatar\">" +
           "<img title=\"kneath\" alt=\"kneath\" src=\"#{gravatar}\" width=\"40\" height=\"40\">" +
           "</a>"
    body = "<p>$kneath$: check it out.</p>"
    res  = filter(body, :gravatar_default_image => default_image)
    assert_equal "<p>#{link}: check it out.</p>", res.to_html
  end

  def test_context_gravatar_default_image_from_username
    username_token = "__replace_with_username__"
    default_image = "http://www.example.com/#{username_token}.jpg"
    gravatar = "https://www.gravatar.com/avatar/#{@email_hash}?s=40&amp;r=g&amp;d=#{CGI.escape(default_image)}"
    link = "<a href=\"/kneath\" class=\"user-avatar\">" +
           "<img title=\"kneath\" alt=\"kneath\" src=\"#{gravatar}\" width=\"40\" height=\"40\">" +
           "</a>"
    body = "<p>$kneath$: check it out.</p>"
    context = {
      :gravatar_default_image => default_image,
      :gravatar_username_token => username_token
    }
    res  = filter(body, context)
    assert_equal "<p>#{link}: check it out.</p>", res.to_html
  end
end

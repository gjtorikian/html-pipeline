require File.expand_path('../../../test_helper', __FILE__)

context "GitHub::HTML::TeamMentionFilter" do
  fixtures do
    @owner     = User.make(:login => "jdoe")
    @collab    = User.make(:login => "tater")
    @org      = Organization.make(:login => "github", :owner => @owner, :plan => 'bronze')
    @team     = Team.make(:name => "enterprise", :organization => @org, :permission => 'pull')
    @github_repo = Repository.make(:organization => @org)
    @random_repo = Repository.make
    @team << @github_repo
    @team << @owner
    @team << @collab
  end

  def filter(html, options = {})
    current_user = stub_everything("stub-user")
    options = { :current_user => @owner, :repository => @github_repo }.merge(options)
    GitHub::HTML::TeamMentionFilter.call(html, options)
  end

  context "valid matches" do
    test "filtering a DocumentFragment" do
      body = "<p>@github/enterprise: check it out.</p>"
      doc  = Nokogiri::HTML::DocumentFragment.parse(body)

      res  = filter(doc)
      assert_same doc, res

      tooltip = %|team members: jdoe and tater|
      span = %|<span class="team-mention tooltipped downwards" title="#{tooltip}">@github/enterprise</span>|
      assert_equal "<p>#{span}: check it out.</p>", res.to_html
    end

    test "filtering plain text" do
      body = "<p>hey @github/enterprise: check it out.</p>"
      res  = filter(body)

      tooltip = %|team members: jdoe and tater|
      span = %|<span class="team-mention tooltipped downwards" title="#{tooltip}">@github/enterprise</span>|
      assert_equal "<p>hey #{span}: check it out.</p>", res.to_html
    end

    test "filtering an email" do
      body = "<p>hey @github/enterprise: check it out.</p>"
      res  = filter(body, :formatter => :email)
      assert_equal '<p>hey <span style="font-weight:bold">@github/enterprise</span>: check it out.</p>', res.to_html
    end

    test "filtering for a collaborator on the team" do
      body = "<p>hey @github/enterprise: check it out.</p>"
      res  = filter(body, :current_user => @collab)
      tooltip = %|team members: jdoe and tater|
      span = %|<span class="team-mention tooltipped downwards" title="#{tooltip}">@github/enterprise</span>|
      assert_equal "<p>hey #{span}: check it out.</p>", res.to_html
    end
  end

  context "non-matches" do
    test "team does not exist" do
      body = "<p>hey @github/dudes: check it out.</p>"
      res  = filter(body)
      assert_equal "<p>hey @github/dudes: check it out.</p>", res.to_html
    end

    test "user does not have access to the team" do
      body = "<p>hey @github/enterprise: check it out.</p>"
      res  = filter(body, :repository => @random_repo)
      assert_equal "<p>hey @github/enterprise: check it out.</p>", res.to_html
    end
  end
end

context "overlapping user and org names" do
  fixtures do
    @user     = User.make(:login => "jdoe")
    @org      = Organization.make(:login => "jdoe-org", :owner => @user, :plan => 'bronze')
    @team     = Team.make(:name => "super-friends-team", :organization => @org, :permission => 'pull')
    @team << @user
    @repo = Repository.make(:organization => @org)
  end

  test "team mention when a team and user name overlap" do
    TestPipeline = GitHub::HTML::Pipeline.new [
      GitHub::HTML::TeamMentionFilter,
      GitHub::HTML::MentionFilter
    ]
    options = { :base_url => "/", :current_user => @user, :repository => @repo }
    body = "<p>hey @jdoe-org/super-friends-team: check it out.</p>"
    result = TestPipeline.to_html(body, options)

    assert_match %r|<p>hey <span class=\"team-mention(.+)" title=\"team members: jdoe\">.+</p>|, result
    assert_match %r|<span(.+)>@jdoe-org/super-friends-team</span>|, result
  end
end

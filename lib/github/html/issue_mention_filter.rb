module GitHub::HTML
  # Sugar for linking to issues.
  #
  # When :repository is provided in the context:
  #   #num
  #   user#num
  #   user/project#num
  #
  # When no :repository is provided in the context:
  #   user/project#num
  #
  # Context options:
  #   :base_url   - Used to construct commit URLs.
  #   :repository - Used to determine current context for bare SHA1 references.
  #
  # This filter writes information to the context hash:
  #   :issues     - An array of IssueReference objects for each issue mentioned.
  #                 You can use IssueReference#close? to determine if the reference
  #                 was prefixed with (close[sd]|fixe[sd]).
  class IssueMentionFilter < Filter
    def call
      if can_access_repo?(repository)
        apply_filter :replace_repo_issue_mentions
        apply_filter :replace_bare_issue_mentions
      else
        apply_filter :replace_global_issue_mentions
      end
      doc
    end

    def apply_filter(method_name)
      doc.search('text()').each do |node|
        content = node.to_html
        next if content !~ /(#|gh-)/i                # perf
        next if has_ancestor?(node, %w(pre code a))  # <-- slow
        html = send(method_name, content)
        next if html == content
        node.replace(html)
      end
    end

    # user/project#num =>
    #   <a href='/user/project/issues/num'>user/project#num</a>
    def replace_global_issue_mentions(text)
      text.gsub(/(^|\s|[(\[{])([\w-]+\/[.\w-]+)#(\d+)\b/) do |match|
        leader, repo, issue = $1, $2, $3
        if reference = issue_reference(nil, issue, repo)
          text = "#{repo}##{issue}"
          url  = reference.issue.url
          title = reference.title
          "#{leader}<a href='#{url}' class='issue-link' title='#{title}'>#{text}</a>"
        else
          match
        end
      end
    end

    # user/project#num =>
    #   <a href='/user/project/issues/num'>user/project#num</a>
    # user#num =>
    #   <a href='/user/project/issues/num'>user#num</a>
    def replace_repo_issue_mentions(text)
      text.gsub(/(^|\s|[(\[{])([\w-]+\/?[.\w-]*)#(\d+)\b/) do |match|
        leader, repo, issue = $1, $2, $3
        if reference = issue_reference(nil, issue, repo)
          text = "#{repo}##{issue}"
          url  = reference.issue.url
          title = reference.title
          "#{leader}<a href='#{url}' class='issue-link' title='#{title}'>#{text}</a>"
        else
          match
        end
      end
    end

    # #num =>
    #   <a href='/user/project/issues/num'>#num</a>
    def replace_bare_issue_mentions(text)
      text.gsub(/(^|close[sd]? |fixe[sd]? |resolve[sd]? |fix | |\W)(gh-|#)(\d+)\b/i) do |match|
        word, pound, number = $1, $2, $3.to_i
        if reference = issue_reference(word, number)
          issue = reference.issue
          title = reference.title
          "#{word}<a href='#{issue.url}' class='issue-link' title='#{title}'>#{pound}#{number}</a>"
        else
          match
        end
      end
    end

    # Array of IssueReference objects written to the context hash so that
    # callers can find referenced issues.
    def issue_mentions
      result[:issues] ||= []
    end

    # Create an IssueReference for the given issue number and save it in the
    # contect hash's :issue_mentions value.
    #
    # word   - The leading text before the issue number. Used to mark the
    #          IssueReference as closed or not.
    # number - The issue number as an integer.
    # repo   - The Repository object where the issue should be searched for. May
    #          also be a string '<user>/<repo>' value.
    #
    # Returns an IssueReference when the mention is valid, or nil when the
    # issue could not be found.
    def issue_reference(word, number, repo = nil)
      repository = find_repository(repo)
      return unless can_access_repo?(repository)

      # first try to find the issue in the current or explicitly
      # referenced repository
      issue = repository.issues.find_by_number(number)

      # if the issue wasn't found, try searching in the root fork but only when
      # not explicit repository reference was given (i.e., "foo/bar#33" won't
      # search in the root fork).
      if issue.nil? && repo.blank? && (repository = repository.source)
        issue = repository.issues.find_by_number(number)
      end

      # create the IssueReference and add to our list of all issue mentions
      if issue
        reference = IssueReference.new(issue, word.to_s)
        issue_mentions << reference
        reference
      end
    end

    # Get a Repository object for a textual repository reference. When repo is
    # a '<user>/<repo>' string, look up the repository by name. When repo is a
    # '<user>' string, find that user's fork of the context repository.
    #
    # repo - A string repository reference, Repository object, or nil.
    #
    # Returns a Repository object if found, or nil when no repository could be
    # located.
    def find_repository(repo)
      case repo
      when Repository
        repo
      when /^\s*$/, nil
        repository
      when /\//
        Repository.find_by_name_with_owner(repo)
      else
        if repository && user = User.find_by_login(repo)
          repository.network_repositories.find_by_owner_id(user.id)
        end
      end
    end
  end

  # Object added to the context hash to record issue references.
  class IssueReference < Struct.new(:issue, :type)
    def title
      @title ||= Rack::Utils.escape_html(issue.title)
    end

    def close?
      type.to_s =~ /(close|fix|resolve)/i
    end
  end
end

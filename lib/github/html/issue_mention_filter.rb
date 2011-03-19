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
  # This filter does not write additional information to the context.
  class IssueMentionFilter < Filter
    def call
      if repository
        apply_filter :replace_repo_issue_mentions
        apply_filter :replace_bare_issue_mentions
      else
        apply_filter :replace_global_issue_mentions
      end
    end

    def apply_filter(method_name)
      doc.search('text()').each do |node|
        next if !node.content.include?('#')
        next if node.ancestors('pre, code, a').any?
        html = send(method_name, node.content)
        node.replace(html) if html != node.content
      end
    end

    # user/project#num =>
    #   <a href='/user/project/issues/num'>user/project#num</a>
    def replace_global_issue_mentions(text)
      text.gsub(/(^|\s|[(\[{])([\w-]+\/[.\w-]+)#(\d+)\b/) do |match|
        leader, repo, issue = $1, $2, $3
        text = "#{repo}##{issue}"
        "#{leader}<a href='#{issue_url(repo, issue)}'>#{text}</a>"
      end
    end

    # user/project#num =>
    #   <a href='/user/project/issues/num'>user/project#num</a>
    # user#num =>
    #   <a href='/user/project/issues/num'>user#num</a>
    #
    # TODO consider axing the user#num syntax or validate that 1.) the user has a
    # fork and, 2.) the issue exists there.
    def replace_repo_issue_mentions(text)
      text.gsub(/(^|\s|[(\[{])([\w-]+\/?[.\w-]*)#(\d+)\b/) do |match|
        leader, repo, issue = $1, $2, $3
        url  = [repo_url(repo), 'issues', issue].join('/')
        text = "#{repo}##{issue}"
        "#{leader}<a href='#{url}'>#{text}</a>"
      end
    end

    # #num =>
    #   <a href='/user/project/issues/num'>#num</a>
    def replace_bare_issue_mentions(text)
      text = text.gsub(/(^|\s|[(\[{])#(\d+)\b/) do |match|
        leader, issue = $1, $2.to_i
        url  = issue_url(repository.name_with_owner, issue)
        text = "##{issue}"
        "#{leader}<a href='#{url}'>#{text}</a>"
      end
    end

    def repo_url(repo)
      if repo.include?('/')
        [base_url.chomp('/'), repo].join('/')
      else
        # user#num - assume same repo name but different user
        [base_url.chomp('/'), repo, repository.name].join('/')
      end
    end

    def issue_url(repo, issue)
      [base_url.chomp('/'), repo, 'issues', issue].join('/')
    end
  end
end

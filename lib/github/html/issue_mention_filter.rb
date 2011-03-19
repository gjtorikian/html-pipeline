module GitHub::HTML
  # Sugar for linking to issues in full user/repo references.
  #
  # When no repository is provided in the context:
  #   user/project#num
  #
  # When repository is provided in the context:
  #   #num
  #   user#num
  #   user/project#num
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
      base_url = self.base_url.chomp('/')
      text.gsub(/(^|\s|[(\[{])([\w-]+\/[.\w-]+)#(\d+)\b/) do |match|
        leader, repo, issue = $1, $2, $3
        url  = [base_url, repo, 'issues', issue].join('/')
        text = "#{repo}##{issue}"
        "#{leader}<a href='#{url}'>#{text}</a>"
      end
    end

    # user/project#num & user#num =>
    #   <a href='/user/project/issues/num'>user/project#num</a>
    def replace_repo_issue_mentions(text)
      text.gsub(/(^|\s|[(\[{])([\w-]+\/?[.\w-]*)#(\d+)\b/) do |match|
        leader, repo, issue = $1, $2, $3
        repo_url =
          if repo.include?('/')
            [base_url.chomp('/'), repo].join('/')
          else
            # user#num - assume same repo name but different user
            [base_url.chomp('/'), repo, repository.name].join('/')
          end
        url  = [repo_url, 'issues', issue].join('/')
        text = "#{repo}##{issue}"
        "#{leader}<a href='#{url}'>#{text}</a>"
      end
    end

    # #num =>
    #   <a href='/user/project/issues/num'>#num</a>
    def replace_bare_issue_mentions(text)
      text = text.gsub(/(^|\s|[(\[{])#(\d+)\b/) do |match|
        leader, issue = $1, $2.to_i
        url  = [repository.permalink, 'issues', issue].join('/')
        text = "##{issue}"
        "#{leader}<a href='#{url}' class='internal'>#{text}</a>"
      end
    end
  end
end

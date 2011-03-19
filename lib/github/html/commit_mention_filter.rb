module GitHub::HTML
  # Sugar for linking to commit SHA's in full user/repo references. The
  # following syntaxes are supported where SHA is a 7-40 char hex String.
  #
  # When no repository is provided in the context:
  #   user/project@SHA
  #
  # When repository is provided in the context:
  #   SHA (7-40 char)
  #   user@SHA
  #   user/project@SHA
  class CommitMentionFilter < Filter
    def call
      if repository
        apply_filter :replace_repo_commit_mentions
        apply_filter :replace_bare_commit_mentions
      else
        apply_filter :replace_global_commit_mentions
      end
    end

    def apply_filter(method_name)
      doc.search('text()').each do |node|
        text = node.content
        next unless text.include?('@') || text =~ /[0-9a-f]{40}\b/
        next if node.ancestors('pre, code, a').any?
        html = send(method_name, node.content)
        node.replace(html) if html != node.content
      end
    end

    # user/repo@SHA =>
    #   <a href='/user/repo/commit/SHA'>user/repo@SHA</a>
    def replace_global_commit_mentions(text)
      base_url = self.base_url.chomp('/')
      text.gsub(/(^|\s|[({\[])([\w-]+\/[\w.-]+)@([0-9a-f]{7,40})\b/) do |match|
        leader, repo, sha = $1, $2, $3
        url   = [base_url, repo, 'commit', sha].join('/')
        text  = "#{repo}@#{sha[0, 7]}"
        "#{leader}<a href='#{url}'>#{text}</a>"
      end
    end

    # user/repo@SHA =>
    #   <a href='/user/repo/commit/SHA'>user/repo@SHA</a>
    # user@SHA =>
    #   <a href='/user/repo/commit/SHA'>user@SHA</a>
    def replace_repo_commit_mentions(text)
      text.gsub(/(^|[\s({\[])([\w-]+\/?[\w.-]*)?@([0-9a-f]{7,40})\b/) do |match|
        leader, repo, sha = $1, $2, $3
        repo_url =
          if repo.nil? || repo.empty?
            repository.permalink
          elsif repo.include?('/')
            [base_url.chomp('/'), repo].join('/')
          else
            # user#num - assume same repo name but different user
            [base_url.chomp('/'), repo, repository.name].join('/')
          end
        url  = [repo_url, 'commit', sha].join('/')
        text = "#{repo}@#{sha[0, 7]}"
        "#{leader}<a href='#{url}'>#{text}</a>"
      end
    end

    # SHA =>
    #   <a href='/user/repo/commit/SHA'>user/repo@SHA</a>
    def replace_bare_commit_mentions(text)
      text.gsub(/(^|[({@\s\[])([0-9a-f]{40})\b/) do |match|
        leader, sha = $1, $2
        url = [repository.permalink, 'commit', sha].join('/')
        "#{leader}<a href='#{url}'>#{sha[0, 7]}</a>"
      end
    end
  end
end

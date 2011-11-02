module GitHub::HTML
  # Sugar for linking to commit SHA's. The following syntaxes are
  # supported where SHA is a 7-40 char hex String.
  #
  # When :repository is provided in the context:
  #   SHA (7-40 char)
  #   user@SHA
  #   user/project@SHA
  #
  # When no :repository is provided in the context:
  #   user/project@SHA
  #
  # Context options:
  #   :base_url   - Used to construct commit URLs.
  #   :repository - Used to determine current context for bare SHA1 references.
  #
  # This filter does not write additional information to the context.
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
        content = node.to_html
        next unless content.include?('@') || content =~ /[0-9a-f]{7,40}\b/
        next if node.ancestors('pre, code, a').any?
        html = send(method_name, content)
        next if html == content
        node.replace(html)
      end
    end

    # user/repo@SHA =>
    #   <a href='/user/repo/commit/SHA'>user/repo@SHA</a>
    def replace_global_commit_mentions(text)
      text.gsub(/(^|\s|[({\[])([\w-]+\/[\w.-]+)@([0-9a-f]{7,40})\b/) do |match|
        leader, repo, sha = $1, $2, $3
        text  = "#{repo}@<tt>#{sha[0, 7]}</tt>"
        "#{leader}<a href='#{commit_url(repo, sha)}' class='commit-link'>#{text}</a>"
      end
    end

    # user/repo@SHA =>
    #   <a href='/user/repo/commit/SHA'>user/repo@SHA</a>
    # user@SHA =>
    #   <a href='/user/repo/commit/SHA'>user@SHA</a>
    def replace_repo_commit_mentions(text)
      text.gsub(/(^|[\s({\[])([\w-]+\/?[\w.-]*)?@([0-9a-f]{7,40})\b/) do |match|
        leader, repo, sha = $1, $2, $3
        url  = [repo_url(repo), 'commit', sha].join('/')
        text = "#{repo}@<tt>#{sha[0, 7]}</tt>"
        "#{leader}<a href='#{url}' class='commit-link'>#{text}</a>"
      end
    end

    # SHA =>
    #   <a href='/user/repo/commit/SHA'>SHA</a>
    def replace_bare_commit_mentions(text)
      text.gsub(/(^|[({@\s\[])([0-9a-f]{7,40})\b/) do |match|
        leader, sha = $1, $2
        url = [repo_url, 'commit', sha].join('/')

        if reference = commit_reference(sha)
          "#{leader}<a href='#{url}' class='commit-link'><tt>#{reference.short_sha}</tt></a>"
        else
          match
        end
      end
    end

    class CommitReference
      def initialize(repository, commit)
        @repository = repository
        @commit     = commit
      end

      attr_reader :repository, :commit

      def short_sha
        @commit.sha[0, 7]
      end
    end
    FakeCommit = Struct.new(:sha)

    def commit_mentions
      context[:commits] ||= []
    end

    def commit_reference(sha)
      sha = repository.walker.ref_to_sha(sha)

      if commit = repository.commit(sha)
        reference = CommitReference.new(repository, commit)
        commit_mentions << reference
        reference
      else
        CommitReference.new(repository, FakeCommit.new(sha))
      end
    end

    def repo_url(repo=nil)
      if repo.nil? || repo.empty?
        [base_url.chomp('/'), repository.name_with_owner].join('/')
      elsif repo.include?('/')
        [base_url.chomp('/'), repo].join('/')
      else
        # user#num - assume same repo name but different user
        [base_url.chomp('/'), repo, repository.name].join('/')
      end
    end

    def commit_url(repo, commit_id)
      [base_url.chomp('/'), repo, 'commit', commit_id].join('/')
    end
  end
end

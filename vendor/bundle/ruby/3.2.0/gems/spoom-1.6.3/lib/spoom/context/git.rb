# typed: strict
# frozen_string_literal: true

module Spoom
  module Git
    class Commit < T::Struct
      class << self
        # Parse a line formatted as `%h %at` into a `Commit`
        #: (String string) -> Commit?
        def parse_line(string)
          sha, epoch = string.split(" ", 2)
          return unless sha && epoch

          time = Time.strptime(epoch, "%s")
          Commit.new(sha: sha, time: time)
        end
      end

      const :sha, String
      const :time, Time

      #: -> Integer
      def timestamp
        time.to_i
      end
    end
  end

  class Context
    # Git features for a context
    module Git
      extend T::Helpers

      requires_ancestor { Context }

      # Run a command prefixed by `git` in this context directory
      #: (String command) -> ExecResult
      def git(command)
        exec("git #{command}")
      end

      # Run `git init` in this context directory
      #
      # Warning: passing a branch will run `git init -b <branch>` which is only available in git 2.28+.
      # In older versions, use `git_init!` followed by `git("checkout -b <branch>")`.
      #: (?branch: String?) -> ExecResult
      def git_init!(branch: nil)
        if branch
          git("init -b #{branch}")
        else
          git("init")
        end
      end

      # Run `git checkout` in this context directory
      #: (?ref: String) -> ExecResult
      def git_checkout!(ref: "main")
        git("checkout #{ref}")
      end

      # Run `git checkout -b <branch-name> <ref>` in this context directory
      #: (String branch_name, ?ref: String?) -> ExecResult
      def git_checkout_new_branch!(branch_name, ref: nil)
        if ref
          git("checkout -b #{branch_name} #{ref}")
        else
          git("checkout -b #{branch_name}")
        end
      end

      # Run `git add . && git commit` in this context directory
      #: (?message: String, ?time: Time, ?allow_empty: bool) -> ExecResult
      def git_commit!(message: "message", time: Time.now.utc, allow_empty: false)
        git("add --all")

        args = ["-m '#{message}'", "--date '#{time}'"]
        args << "--allow-empty" if allow_empty

        exec("GIT_COMMITTER_DATE=\"#{time}\" git -c commit.gpgsign=false commit #{args.join(" ")}")
      end

      # Get the current git branch in this context directory
      #: -> String?
      def git_current_branch
        res = git("branch --show-current")
        return unless res.status

        res.out.strip
      end

      # Run `git diff` in this context directory
      #: (*String arg) -> ExecResult
      def git_diff(*arg)
        git("diff #{arg.join(" ")}")
      end

      # Get the last commit in the currently checked out branch
      #: (?short_sha: bool) -> Spoom::Git::Commit?
      def git_last_commit(short_sha: true)
        res = git_log("HEAD --format='%#{short_sha ? "h" : "H"} %at' -1")
        return unless res.status

        out = res.out.strip
        return if out.empty?

        Spoom::Git::Commit.parse_line(out)
      end

      #: (*String arg) -> ExecResult
      def git_log(*arg)
        git("log #{arg.join(" ")}")
      end

      # Run `git push <remote> <ref>` in this context directory
      #: (String remote, String ref, ?force: bool) -> ExecResult
      def git_push!(remote, ref, force: false)
        git("push #{force ? "-f" : ""} #{remote} #{ref}")
      end

      #: (*String arg) -> ExecResult
      def git_show(*arg)
        git("show #{arg.join(" ")}")
      end

      # Is there uncommitted changes in this context directory?
      #: (?path: String) -> bool
      def git_workdir_clean?(path: ".")
        git_diff("HEAD").out.empty?
      end
    end
  end
end

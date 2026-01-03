# typed: strict
# frozen_string_literal: true

module Spoom
  class Context
    # Sorbet features for a context
    module Sorbet
      extend T::Helpers

      requires_ancestor { Context }

      # Run `bundle exec srb` in this context directory
      #: (*String arg, ?sorbet_bin: String?, ?capture_err: bool) -> ExecResult
      def srb(*arg, sorbet_bin: nil, capture_err: true)
        res = if sorbet_bin
          exec("#{sorbet_bin} #{arg.join(" ")}", capture_err: capture_err)
        else
          bundle_exec("srb #{arg.join(" ")}", capture_err: capture_err)
        end

        case res.exit_code
        when Spoom::Sorbet::KILLED_CODE
          raise Spoom::Sorbet::Error::Killed.new("Sorbet was killed.", res)
        when Spoom::Sorbet::SEGFAULT_CODE
          raise Spoom::Sorbet::Error::Segfault.new("Sorbet segfaulted.", res)
        end

        res
      end

      #: (*String arg, ?sorbet_bin: String?, ?capture_err: bool) -> ExecResult
      def srb_tc(*arg, sorbet_bin: nil, capture_err: true)
        arg.prepend("tc") unless sorbet_bin
        T.unsafe(self).srb(*arg, sorbet_bin: sorbet_bin, capture_err: capture_err)
      end

      #: (*String arg, ?sorbet_bin: String?, ?capture_err: bool) -> Hash[String, Integer]?
      def srb_metrics(*arg, sorbet_bin: nil, capture_err: true)
        metrics_file = "metrics.tmp"

        T.unsafe(self).srb_tc(
          "--metrics-file",
          metrics_file,
          *arg,
          sorbet_bin: sorbet_bin,
          capture_err: capture_err,
        )
        return unless file?(metrics_file)

        metrics_path = absolute_path_to(metrics_file)
        metrics = Spoom::Sorbet::MetricsParser.parse_file(metrics_path)
        remove!(metrics_file)
        metrics
      end

      # List all files typechecked by Sorbet from its `config`
      #: (?with_config: Spoom::Sorbet::Config?, ?include_rbis: bool) -> Array[String]
      def srb_files(with_config: nil, include_rbis: true)
        config = with_config || sorbet_config

        allowed_extensions = config.allowed_extensions
        allowed_extensions = Spoom::Sorbet::Config::DEFAULT_ALLOWED_EXTENSIONS if allowed_extensions.empty?
        allowed_extensions -= [".rbi"] unless include_rbis

        excluded_patterns = config.ignore.map do |string|
          # We need to simulate the behavior of Sorbet's `--ignore` flag.
          #
          # From Sorbet docs on `--ignore`:
          # > Ignores input files that contain the given string in their paths (relative to the input path passed to
          # > Sorbet). Strings beginning with / match against the prefix of these relative paths; others are substring
          # > matches. Matches must be against whole folder and file names, so `foo` matches `/foo/bar.rb` and
          # > `/bar/foo/baz.rb` but not `/foo.rb` or `/foo2/bar.rb`.
          string = if string.start_with?("/")
            # Strings beginning with / match against the prefix of these relative paths
            File.join(absolute_path, string)
          else
            # Others are substring matches
            File.join(absolute_path, "**", string)
          end
          # Matches must be against whole folder and file names
          "#{string.delete_suffix("/")}{,/**}"
        end

        collector = FileCollector.new(allow_extensions: allowed_extensions, exclude_patterns: excluded_patterns)
        collector.visit_paths(config.paths.map { |path| absolute_path_to(path) })
        collector.files.map { |file| file.delete_prefix("#{absolute_path}/") }.sort
      end

      # List all files typechecked by Sorbet from its `config` that matches `strictness`
      #: (String strictness, ?with_config: Spoom::Sorbet::Config?, ?include_rbis: bool) -> Array[String]
      def srb_files_with_strictness(strictness, with_config: nil, include_rbis: true)
        srb_files(with_config: with_config, include_rbis: include_rbis)
          .select { |file| read_file_strictness(file) == strictness }
      end

      #: (*String arg, ?sorbet_bin: String?, ?capture_err: bool) -> String?
      def srb_version(*arg, sorbet_bin: nil, capture_err: true)
        res = T.unsafe(self).srb_tc("--no-config", "--version", *arg, sorbet_bin: sorbet_bin, capture_err: capture_err)
        return unless res.status

        res.out.split(" ")[2]
      end

      # Does this context has a `sorbet/config` file?
      #: -> bool
      def has_sorbet_config?
        file?(Spoom::Sorbet::CONFIG_PATH)
      end

      #: -> Spoom::Sorbet::Config
      def sorbet_config
        Spoom::Sorbet::Config.parse_string(read_sorbet_config)
      end

      # Read the contents of `sorbet/config` in this context directory
      #: -> String
      def read_sorbet_config
        read(Spoom::Sorbet::CONFIG_PATH)
      end

      # Set the `contents` of `sorbet/config` in this context directory
      #: (String contents, ?append: bool) -> void
      def write_sorbet_config!(contents, append: false)
        write!(Spoom::Sorbet::CONFIG_PATH, contents, append: append)
      end

      # Read the strictness sigil from the file at `relative_path` (returns `nil` if no sigil)
      #: (String relative_path) -> String?
      def read_file_strictness(relative_path)
        Spoom::Sorbet::Sigils.file_strictness(absolute_path_to(relative_path))
      end

      # Get the commit introducing the `sorbet/config` file
      #: -> Spoom::Git::Commit?
      def sorbet_intro_commit
        res = git_log("--diff-filter=A --format='%h %at' -1 -- sorbet/config")
        return unless res.status

        out = res.out.strip
        return if out.empty?

        Spoom::Git::Commit.parse_line(out)
      end

      # Get the commit removing the `sorbet/config` file
      #: -> Spoom::Git::Commit?
      def sorbet_removal_commit
        res = git_log("--diff-filter=D --format='%h %at' -1 -- sorbet/config")
        return unless res.status

        out = res.out.strip
        return if out.empty?

        Spoom::Git::Commit.parse_line(out)
      end
    end
  end
end

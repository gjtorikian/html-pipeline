# typed: true
# frozen_string_literal: true

require_relative "../../coverage"
require_relative "../../timeline"

module Spoom
  module Cli
    module Srb
      class Coverage < Thor
        include Helper

        DATA_DIR = "spoom_data"

        default_task :snapshot

        desc "snapshot", "Run srb tc and display metrics"
        option :save, type: :string, lazy_default: DATA_DIR, desc: "Save snapshot data as json"
        option :rbi, type: :boolean, default: true, desc: "Include RBI files in metrics"
        option :sorbet, type: :string, desc: "Path to custom Sorbet bin"
        def snapshot
          context = context_requiring_sorbet!
          sorbet = options[:sorbet]

          snapshot = Spoom::Coverage.snapshot(context, rbi: options[:rbi], sorbet_bin: sorbet)
          snapshot.print

          save_dir = options[:save]
          return unless save_dir

          FileUtils.mkdir_p(save_dir)
          file = "#{save_dir}/#{snapshot.commit_sha || snapshot.timestamp}.json"
          File.write(file, snapshot.to_json)
          say("\nSnapshot data saved under `#{file}`")
        end

        desc "timeline", "Replay a project and collect metrics"
        option :from, type: :string, desc: "From commit date"
        option :to, type: :string, default: Time.now.strftime("%F"), desc: "To commit date"
        option :save, type: :string, lazy_default: DATA_DIR, desc: "Save snapshot data as json"
        option :bundle_install, type: :boolean, desc: "Execute `bundle install` before collecting metrics"
        option :sorbet, type: :string, desc: "Path to custom Sorbet bin"
        def timeline
          context = context_requiring_sorbet!
          path = exec_path
          sorbet = options[:sorbet]

          ref_before = context.git_current_branch
          ref_before = context.git_last_commit&.sha unless ref_before
          unless ref_before
            say_error("Not in a git repository")
            say_error("\nSpoom needs to checkout into your previous commits to build the timeline.", status: nil)
            exit(1)
          end

          unless context.git_workdir_clean?
            say_error("Uncommitted changes")
            say_error(<<~ERR, status: nil)

              Spoom needs to checkout into your previous commits to build the timeline."

              Please `git commit` or `git stash` your changes then try again
            ERR
            exit(1)
          end

          save_dir = options[:save]
          FileUtils.mkdir_p(save_dir) if save_dir

          from = parse_time(options[:from], "--from")
          to = parse_time(options[:to], "--to")

          unless from
            intro_commit = context.sorbet_intro_commit
            intro_commit = T.must(intro_commit) # we know it's in there since in_sorbet_project!
            from = intro_commit.time
          end

          timeline = Spoom::Timeline.new(context, from, to)
          ticks = timeline.ticks

          if ticks.empty?
            say_error("No commits to replay, try different `--from` and `--to` options")
            exit(1)
          end

          ticks.each_with_index do |commit, i|
            say("Analyzing commit `#{commit.sha}` - #{commit.time.strftime("%F")} (#{i + 1} / #{ticks.size})")

            context.git_checkout!(ref: commit.sha)

            snapshot = nil #: Spoom::Coverage::Snapshot?
            if options[:bundle_install]
              Bundler.with_unbundled_env do
                next unless bundle_install(path, commit.sha)

                snapshot = Spoom::Coverage.snapshot(context, sorbet_bin: sorbet)
              end
            else
              snapshot = Spoom::Coverage.snapshot(context, sorbet_bin: sorbet)
            end
            next unless snapshot

            snapshot.print(indent_level: 2)
            say("\n")

            next unless save_dir

            file = "#{save_dir}/#{commit.sha}.json"
            File.write(file, snapshot.to_json)
            say("  Snapshot data saved under `#{file}`\n\n")
          end
          context.git_checkout!(ref: ref_before)
        end

        desc "report", "Produce a typing coverage report"
        option :data, type: :string, default: DATA_DIR, desc: "Snapshots JSON data"
        option :file,
          type: :string,
          default: "spoom_report.html",
          aliases: :f,
          desc: "Save report to file"
        option :color_ignore,
          type: :string,
          default: Spoom::Coverage::D3::COLOR_IGNORE,
          desc: "Color used for typed: ignore"
        option :color_false,
          type: :string,
          default: Spoom::Coverage::D3::COLOR_FALSE,
          desc: "Color used for typed: false"
        option :color_true,
          type: :string,
          default: Spoom::Coverage::D3::COLOR_TRUE,
          desc: "Color used for typed: true"
        option :color_strict,
          type: :string,
          default: Spoom::Coverage::D3::COLOR_STRICT,
          desc: "Color used for typed: strict"
        option :color_strong,
          type: :string,
          default: Spoom::Coverage::D3::COLOR_STRONG,
          desc: "Color used for typed: strong"
        def report
          context = context_requiring_sorbet!

          data_dir = options[:data]
          files = Dir.glob("#{data_dir}/*.json")
          if files.empty?
            message_no_data(data_dir)
            exit(1)
          end

          snapshots = files.sort.map do |file|
            json = File.read(file)
            Spoom::Coverage::Snapshot.from_json(json)
          end.filter(&:commit_timestamp).sort_by!(&:commit_timestamp)

          palette = Spoom::Coverage::D3::ColorPalette.new(
            ignore: options[:color_ignore],
            false: options[:color_false],
            true: options[:color_true],
            strict: options[:color_strict],
            strong: options[:color_strong],
          )

          report = Spoom::Coverage.report(context, snapshots, palette: palette)
          file = options[:file]
          File.write(file, report.html)
          say("Report generated under `#{file}`")
          say("\nUse `spoom coverage open` to open it.")
        end

        desc "open", "Open the typing coverage report"
        def open(file = "spoom_report.html")
          unless File.exist?(file)
            say_error("No report file to open `#{file}`")
            say_error(<<~ERR, status: nil)

              If you already generated a report under another name use #{blue("spoom coverage open PATH")}.

              To generate a report run #{blue("spoom coverage report")}.
            ERR
            exit(1)
          end

          exec("open #{file}")
        end

        no_commands do
          def parse_time(string, option)
            return unless string

            Time.parse(string)
          rescue ArgumentError
            say_error("Invalid date `#{string}` for option `#{option}` (expected format `YYYY-MM-DD`)")
            exit(1)
          end

          def bundle_install(path, sha)
            opts = {}
            opts[:chdir] = path
            out, status = Open3.capture2e("bundle install", opts)
            unless status.success?
              say_error("Can't run `bundle install` for commit `#{sha}`. Skipping snapshot")
              say_error(out, status: nil)
              return false
            end
            true
          end

          def message_no_data(file)
            say_error("No snapshot files found in `#{file}`")
            say_error(<<~ERR, status: nil)

              If you already generated snapshot files under another directory use #{blue("spoom coverage report PATH")}.

              To generate snapshot files run #{blue("spoom coverage timeline --save")}.
            ERR
          end
        end
      end
    end
  end
end

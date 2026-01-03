# typed: strict
# frozen_string_literal: true

require_relative "coverage/snapshot"
require_relative "coverage/report"
require_relative "file_tree"

require "date"

module Spoom
  module Coverage
    class << self
      #: (Context context, ?rbi: bool, ?sorbet_bin: String?) -> Snapshot
      def snapshot(context, rbi: true, sorbet_bin: nil)
        config = context.sorbet_config
        config.allowed_extensions.push(".rb", ".rbi") if config.allowed_extensions.empty?

        new_config = config.copy
        new_config.allowed_extensions.reject! { |ext| !rbi && ext == ".rbi" }
        flags = [
          "--no-config",
          "--no-error-sections",
          "--no-error-count",
          "--isolate-error-code=0",
          new_config.options_string,
        ]

        metrics = context.srb_metrics(*flags, sorbet_bin: sorbet_bin)

        # Collect extra information using a different configuration
        flags << "--ignore sorbet/rbi/"
        metrics_without_rbis = context.srb_metrics(*flags, sorbet_bin: sorbet_bin)

        snapshot = Snapshot.new
        return snapshot unless metrics

        last_commit = context.git_last_commit
        snapshot.commit_sha = last_commit&.sha
        snapshot.commit_timestamp = last_commit&.timestamp

        snapshot.files = metrics.fetch("types.input.files", 0)
        snapshot.modules = metrics.fetch("types.input.modules.total", 0)
        snapshot.classes = metrics.fetch("types.input.classes.total", 0)
        snapshot.singleton_classes = metrics.fetch("types.input.singleton_classes.total", 0)
        snapshot.methods_with_sig = metrics.fetch("types.sig.count", 0)
        snapshot.methods_without_sig = metrics.fetch("types.input.methods.total", 0) - snapshot.methods_with_sig
        snapshot.calls_typed = metrics.fetch("types.input.sends.typed", 0)
        snapshot.calls_untyped = metrics.fetch("types.input.sends.total", 0) - snapshot.calls_typed

        snapshot.duration += metrics.fetch("run.utilization.system_time.us", 0)
        snapshot.duration += metrics.fetch("run.utilization.user_time.us", 0)

        if metrics_without_rbis
          snapshot.methods_with_sig_excluding_rbis = metrics_without_rbis.fetch("types.sig.count", 0)
          snapshot.methods_without_sig_excluding_rbis = metrics_without_rbis.fetch(
            "types.input.methods.total",
            0,
          ) - snapshot.methods_with_sig_excluding_rbis
        end

        Snapshot::STRICTNESSES.each do |strictness|
          if metrics.key?("types.input.files.sigil.#{strictness}")
            snapshot.sigils[strictness] = T.must(metrics["types.input.files.sigil.#{strictness}"])
          end
          if metrics_without_rbis&.key?("types.input.files.sigil.#{strictness}")
            snapshot.sigils_excluding_rbis[strictness] =
              T.must(metrics_without_rbis["types.input.files.sigil.#{strictness}"])
          end
        end

        snapshot.version_static = context.gem_version_from_gemfile_lock("sorbet-static").to_s
        snapshot.version_runtime = context.gem_version_from_gemfile_lock("sorbet-runtime").to_s

        files = context.srb_files(with_config: new_config)
        snapshot.rbi_files = files.count { |file| file.end_with?(".rbi") }

        snapshot
      end

      #: (Context context, Array[Snapshot] snapshots, palette: D3::ColorPalette) -> Report
      def report(context, snapshots, palette:)
        intro_commit = context.sorbet_intro_commit

        file_tree = file_tree(context)
        v = FileTree::CollectScores.new(context)
        v.visit_tree(file_tree)

        Report.new(
          project_name: File.basename(context.absolute_path),
          palette: palette,
          snapshots: snapshots,
          file_tree: file_tree,
          nodes_strictnesses: v.strictnesses,
          nodes_strictness_scores: v.scores,
          sorbet_intro_commit: intro_commit&.sha,
          sorbet_intro_date: intro_commit&.time,
        )
      end

      #: (Context context) -> FileTree
      def file_tree(context)
        config = context.sorbet_config
        config.ignore += ["test"]

        files = context.srb_files(with_config: config, include_rbis: false)
        FileTree.new(files)
      end
    end
  end
end

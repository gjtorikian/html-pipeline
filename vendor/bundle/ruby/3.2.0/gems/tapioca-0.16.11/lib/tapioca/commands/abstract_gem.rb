# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class AbstractGem < Command
      include SorbetHelper
      include RBIFilesHelper

      abstract!

      sig do
        params(
          gem_names: T::Array[String],
          exclude: T::Array[String],
          include_dependencies: T::Boolean,
          prerequire: T.nilable(String),
          postrequire: String,
          typed_overrides: T::Hash[String, String],
          outpath: Pathname,
          file_header: T::Boolean,
          include_doc: T::Boolean,
          include_loc: T::Boolean,
          include_exported_rbis: T::Boolean,
          number_of_workers: T.nilable(Integer),
          auto_strictness: T::Boolean,
          dsl_dir: String,
          rbi_formatter: RBIFormatter,
          halt_upon_load_error: T::Boolean,
          lsp_addon: T.nilable(T::Boolean),
        ).void
      end
      def initialize(
        gem_names:,
        exclude:,
        include_dependencies:,
        prerequire:,
        postrequire:,
        typed_overrides:,
        outpath:,
        file_header:,
        include_doc:,
        include_loc:,
        include_exported_rbis:,
        number_of_workers: nil,
        auto_strictness: true,
        dsl_dir: DEFAULT_DSL_DIR,
        rbi_formatter: DEFAULT_RBI_FORMATTER,
        halt_upon_load_error: true,
        lsp_addon: false
      )
        @gem_names = gem_names
        @exclude = exclude
        @include_dependencies = include_dependencies
        @prerequire = prerequire
        @postrequire = postrequire
        @typed_overrides = typed_overrides
        @outpath = outpath
        @file_header = file_header
        @number_of_workers = number_of_workers
        @auto_strictness = auto_strictness
        @dsl_dir = dsl_dir
        @rbi_formatter = rbi_formatter
        @lsp_addon = lsp_addon

        super()

        @bundle = T.let(Gemfile.new(exclude), Gemfile)
        @existing_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
        @expected_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
        @include_doc = T.let(include_doc, T::Boolean)
        @include_loc = T.let(include_loc, T::Boolean)
        @include_exported_rbis = include_exported_rbis
        @halt_upon_load_error = halt_upon_load_error
      end

      private

      sig { params(gem: Gemfile::GemSpec).void }
      def compile_gem_rbi(gem)
        gem_name = set_color(gem.name, :yellow, :bold)

        rbi = RBI::File.new(strictness: @typed_overrides[gem.name] || "true")

        @rbi_formatter.write_header!(
          rbi,
          default_command(:gem, gem.name),
          reason: "types exported from the `#{gem.name}` gem",
        ) if @file_header

        rbi.root = Runtime::Trackers::Autoload.with_disabled_exits do
          Tapioca::Gem::Pipeline.new(
            gem,
            include_doc: @include_doc,
            include_loc: @include_loc,
            error_handler: ->(error) {
              say_error(error, :bold, :red)
            },
          ).compile
        end

        merge_with_exported_rbi(gem, rbi) if @include_exported_rbis

        if rbi.empty?
          @rbi_formatter.write_empty_body_comment!(rbi)
          say("Compiled #{gem_name} (empty output)", :yellow)
        else
          say("Compiled #{gem_name}", :green)
        end

        rbi_string = @rbi_formatter.print_file(rbi)
        create_file(@outpath / gem.rbi_file_name, rbi_string)

        T.unsafe(Pathname).glob((@outpath / "#{gem.name}@*.rbi").to_s) do |file|
          remove_file(file) unless file.basename.to_s == gem.rbi_file_name
        end
      end

      sig { void }
      def perform_removals
        say("Removing RBI files of gems that have been removed:", [:blue, :bold])
        puts

        anything_done = T.let(false, T::Boolean)

        gems = removed_rbis

        shell.indent do
          if gems.empty?
            say("Nothing to do.")
          else
            gems.each do |removed|
              filename = existing_rbi(removed)
              remove_file(filename)
            end

            anything_done = true
          end
        end

        puts

        anything_done
      end

      sig { void }
      def perform_additions
        say("Generating RBI files of gems that are added or updated:", [:blue, :bold])
        puts

        anything_done = T.let(false, T::Boolean)

        gems = added_rbis

        shell.indent do
          if gems.empty?
            say("Nothing to do.")
          else
            Loaders::Gem.load_application(
              bundle: @bundle,
              prerequire: @prerequire,
              postrequire: @postrequire,
              default_command: default_command(:require),
              halt_upon_load_error: @halt_upon_load_error,
            )

            Executor.new(gems, number_of_workers: @number_of_workers).run_in_parallel do |gem_name|
              filename = expected_rbi(gem_name)

              if gem_rbi_exists?(gem_name)
                old_filename = existing_rbi(gem_name)
                move(old_filename, filename) unless old_filename == filename
              end

              gem = T.must(@bundle.gem(gem_name))
              compile_gem_rbi(gem)
              puts
            end
          end

          anything_done = true
        end

        puts

        anything_done
      end

      sig { returns(T::Array[String]) }
      def removed_rbis
        (existing_rbis.keys - expected_rbis.keys).sort
      end

      sig { params(gem_name: String).returns(Pathname) }
      def existing_rbi(gem_name)
        gem_rbi_filename(gem_name, T.must(existing_rbis[gem_name]))
      end

      sig { returns(T::Array[String]) }
      def added_rbis
        expected_rbis.select do |name, value|
          existing_rbis[name] != value
        end.keys.sort
      end

      sig { params(gem_name: String).returns(Pathname) }
      def expected_rbi(gem_name)
        gem_rbi_filename(gem_name, T.must(expected_rbis[gem_name]))
      end

      sig { params(gem_name: String).returns(T::Boolean) }
      def gem_rbi_exists?(gem_name)
        existing_rbis.key?(gem_name)
      end

      sig { params(diff: T::Hash[String, Symbol], command: Symbol).void }
      def report_diff_and_exit_if_out_of_date(diff, command)
        if diff.empty?
          say("Nothing to do, all RBIs are up-to-date.")
        else
          reasons = diff.group_by(&:last).sort.map do |cause, diff_for_cause|
            build_error_for_files(cause, diff_for_cause.map(&:first))
          end.join("\n")

          raise Thor::Error, <<~ERROR
            #{set_color("RBI files are out-of-date. In your development environment, please run:", :green)}
              #{set_color("`#{default_command(command)}`", :green, :bold)}
            #{set_color("Once it is complete, be sure to commit and push any changes", :green)}

            #{set_color("Reason:", :red)}
            #{reasons}
          ERROR
        end
      end

      sig { params(old_filename: Pathname, new_filename: Pathname).void }
      def move(old_filename, new_filename)
        say("-> Moving: #{old_filename} to #{new_filename}")
        old_filename.rename(new_filename.to_s)
      end

      sig { returns(T::Hash[String, String]) }
      def existing_rbis
        @existing_rbis ||= Pathname.glob((@outpath / "*@*.rbi").to_s)
          .to_h { |f| T.cast(f.basename(".*").to_s.split("@", 2), [String, String]) }
      end

      sig { returns(T::Hash[String, String]) }
      def expected_rbis
        @expected_rbis ||= @bundle.dependencies
          .reject { |gem| @exclude.include?(gem.name) }
          .to_h { |gem| [gem.name, gem.version.to_s] }
      end

      sig { params(gem_name: String, version: String).returns(Pathname) }
      def gem_rbi_filename(gem_name, version)
        @outpath / "#{gem_name}@#{version}.rbi"
      end

      sig { params(cause: Symbol, files: T::Array[String]).returns(String) }
      def build_error_for_files(cause, files)
        "  File(s) #{cause}:\n  - #{files.join("\n  - ")}"
      end

      sig { params(gem: Gemfile::GemSpec, file: RBI::File).void }
      def merge_with_exported_rbi(gem, file)
        return file unless gem.export_rbi_files?

        tree = gem.exported_rbi_tree

        unless tree.conflicts.empty?
          say_error("\n\n  RBIs exported by `#{gem.name}` contain conflicts and can't be used:", :yellow)

          tree.conflicts.each do |conflict|
            say_error("\n    #{conflict}", :yellow)
            say_error("    Found at:", :yellow)
            say_error("      #{conflict.left.loc}", :yellow)
            say_error("      #{conflict.right.loc}", :yellow)
          end

          return file
        end

        file.root = RBI::Rewriters::Merge.merge_trees(file.root, tree, keep: RBI::Rewriters::Merge::Keep::LEFT)
      rescue RBI::ParseError => e
        say_error("\n\n  RBIs exported by `#{gem.name}` contain errors and can't be used:", :yellow)
        say_error("Cause: #{e.message} (#{e.location})")
      end
    end
  end
end

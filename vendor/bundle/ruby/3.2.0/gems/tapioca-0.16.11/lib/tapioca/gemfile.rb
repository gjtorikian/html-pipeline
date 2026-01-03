# typed: strict
# frozen_string_literal: true

require "tapioca/bundler_ext/auto_require_hook"

module Tapioca
  class Gemfile
    extend(T::Sig)

    Spec = T.type_alias do
      T.any(
        ::Bundler::StubSpecification,
        ::Gem::Specification,
      )
    end

    sig { returns(Bundler::Definition) }
    attr_reader(:definition)

    sig { returns(T::Array[GemSpec]) }
    attr_reader(:dependencies)

    sig { returns(T::Array[String]) }
    attr_reader(:missing_specs)

    sig { params(excluded_gems: T::Array[String]).void }
    def initialize(excluded_gems)
      @gemfile = T.let(File.new(Bundler.default_gemfile), File)
      @lockfile = T.let(File.new(Bundler.default_lockfile), File)
      @definition = T.let(Bundler::Dsl.evaluate(gemfile, lockfile, {}), Bundler::Definition)
      @excluded_gems = excluded_gems

      dependencies, missing_specs = load_dependencies

      @dependencies = T.let(dependencies, T::Array[GemSpec])
      @missing_specs = T.let(missing_specs, T::Array[String])
    end

    sig { params(gem_name: String).returns(T.nilable(GemSpec)) }
    def gem(gem_name)
      dependencies.detect { |dep| dep.name == gem_name }
    end

    sig { void }
    def require_bundle
      BundlerExt::AutoRequireHook.override_require_false(exclude: @excluded_gems) do
        T.unsafe(runtime).require(*groups)
      end
    end

    private

    sig { returns(File) }
    attr_reader(:gemfile, :lockfile)

    sig { returns([T::Array[GemSpec], T::Array[String]]) }
    def load_dependencies
      materialized_dependencies, missing_specs = materialize_deps
      dependencies = materialized_dependencies
        .map { |spec| GemSpec.new(spec) }
        .reject { |gem| gem.ignore?(dir) }
        .uniq(&:rbi_file_name)
        .sort_by(&:rbi_file_name)
      [dependencies, missing_specs]
    end

    sig { returns([T::Enumerable[Spec], T::Array[String]]) }
    def materialize_deps
      deps = definition.locked_gems.dependencies.except(*@excluded_gems).values
      resolve = definition.resolve
      materialized_dependencies = resolve.materialize(deps)

      if Bundler::VERSION >= "2.6.0"
        missing_specs = resolve.missing_specs.map do |spec|
          "#{spec.name} (#{spec.version})"
        end
      else
        missing_spec_names = materialized_dependencies.missing_specs.map(&:name).to_set
        missing_specs = materialized_dependencies.missing_specs.map do |spec|
          "#{spec.name} (#{spec.version})"
        end
        materialized_dependencies = materialized_dependencies.to_a.reject do |spec|
          missing_spec_names.include?(spec.name)
        end
      end

      [materialized_dependencies, missing_specs]
    end

    sig { returns(Bundler::Runtime) }
    def runtime
      Bundler::Runtime.new(File.dirname(gemfile.path), definition)
    end

    sig { returns(T::Array[Symbol]) }
    def groups
      definition.groups
    end

    sig { returns(String) }
    def dir
      File.expand_path(gemfile.path + "/..")
    end

    class GemSpec
      extend(T::Sig)
      include GemHelper

      class << self
        extend T::Sig

        sig { returns(T::Hash[String, Gemfile::GemSpec]) }
        def spec_lookup_by_file_path
          @lookup ||= T.let(
            [*::Gem::Specification.default_stubs, *::Gem::Specification.stubs]
              .map! { |spec| new(spec.to_spec) }
              .flat_map do |spec|
                spec.files.filter_map { |file| [file.realpath.to_s, spec] if file.exist? }
              end.to_h,
            T.nilable(T::Hash[String, Gemfile::GemSpec]),
          )
        end
      end

      IGNORED_GEMS = T.let(
        [
          "sorbet",
          "sorbet-static",
          "sorbet-runtime",
          "sorbet-static-and-runtime",
          "debug",
          "irb",
          "fakefs",
        ].freeze,
        T::Array[String],
      )

      sig { returns(String) }
      attr_reader :full_gem_path, :version

      sig { returns(T::Array[Pathname]) }
      attr_reader :files

      sig { params(spec: Spec).void }
      def initialize(spec)
        @spec = T.let(spec, Tapioca::Gemfile::Spec)
        real_gem_path = to_realpath(@spec.full_gem_path)
        @full_gem_path = T.let(real_gem_path, String)
        @version = T.let(version_string, String)
        @exported_rbi_files = T.let(nil, T.nilable(T::Array[String]))
        @files = T.let(collect_files, T::Array[Pathname])
      end

      sig { params(other: BasicObject).returns(T::Boolean) }
      def ==(other)
        GemSpec === other && other.name == name && other.version == version
      end

      sig { params(gemfile_dir: String).returns(T::Boolean) }
      def ignore?(gemfile_dir)
        gem_ignored? || gem_in_app_dir?(gemfile_dir, full_gem_path)
      end

      sig { returns(String) }
      def name
        @spec.name
      end

      sig { returns(T::Array[::Gem::Dependency]) }
      def dependencies
        @spec.dependencies
      end

      sig { returns(String) }
      def rbi_file_name
        "#{name}@#{version}.rbi"
      end

      sig { params(path: String).returns(T::Boolean) }
      def contains_path?(path)
        if default_gem?
          files.any? { |file| file.to_s == to_realpath(path) }
        else
          path_in_dir?(to_realpath(path), full_gem_path) || has_parent_gemspec?(path)
        end
      end

      sig { void }
      def parse_yard_docs
        files.each do |path|
          YARD.parse(path.to_s, [], Logger::Severity::FATAL)
        rescue RangeError
          # In some circumstances, YARD will raise an error when parsing a file
          # that is actually valid Ruby. We don't want tapioca to halt in these
          # cases, so we'll rescue the error, pretend like there was no
          # documentation, and move on.
          #
          # This can be removed when https://github.com/lsegal/yard/issues/1536
          # is resolved and released.
          []
        end
      end

      sig { returns(T::Array[String]) }
      def exported_rbi_files
        @exported_rbi_files ||= Dir.glob("#{full_gem_path}/rbi/**/*.rbi").sort
      end

      sig { returns(T::Boolean) }
      def export_rbi_files?
        exported_rbi_files.any?
      end

      sig { returns(RBI::MergeTree) }
      def exported_rbi_tree
        rewriter = RBI::Rewriters::Merge.new(keep: RBI::Rewriters::Merge::Keep::NONE)

        exported_rbi_files.each do |file|
          rbi = RBI::Parser.parse_file(file)
          rewriter.merge(rbi)
        end

        rewriter.tree
      end

      sig { params(file: Pathname).returns(Pathname) }
      def relative_path_for(file)
        if default_gem?
          file.realpath.relative_path_from(RbConfig::CONFIG["rubylibdir"])
        else
          file.realpath.relative_path_from(full_gem_path)
        end
      end

      private

      sig { returns(T::Array[Pathname]) }
      def collect_files
        if default_gem?
          # `Bundler::RemoteSpecification` delegates missing methods to
          # `Gem::Specification`, so `files` actually always exists on spec.
          T.unsafe(@spec).files.map do |file|
            resolve_to_ruby_lib_dir(file)
          end
        else
          @spec.full_require_paths.flat_map do |path|
            Pathname.glob((Pathname.new(path) / "**/*.rb").to_s)
          end
        end
      end

      sig { returns(T.nilable(T::Boolean)) }
      def default_gem?
        @spec.respond_to?(:default_gem?) && @spec.default_gem?
      end

      sig { returns(Regexp) }
      def require_paths_prefix_matcher
        @require_paths_prefix_matcher ||= T.let(
          begin
            require_paths = T.unsafe(@spec).require_paths
            prefix_matchers = require_paths.map { |rp| Regexp.new("^#{rp}/") }
            Regexp.union(prefix_matchers)
          end,
          T.nilable(Regexp),
        )
      end

      sig { params(file: String).returns(Pathname) }
      def resolve_to_ruby_lib_dir(file)
        # We want to match require prefixes but fallback to an empty match
        # if none of the require prefixes actually match. This is so that
        # we can always replace the match with the Ruby lib directory and
        # we would have properly resolved the file under the Ruby lib dir.
        prefix_matcher = Regexp.union(require_paths_prefix_matcher, //)

        ruby_lib_dir = RbConfig::CONFIG["rubylibdir"]
        file = file.sub(prefix_matcher, "#{ruby_lib_dir}/")

        Pathname.new(file).expand_path
      end

      sig { returns(String) }
      def version_string
        version = @spec.version.to_s
        version += "-#{@spec.source.revision}" if Bundler::Source::Git === @spec.source
        version
      end

      sig { params(path: String).returns(T::Boolean) }
      def has_parent_gemspec?(path)
        # For some Git installed gems the location of the loaded file can
        # be different from the gem path as indicated by the spec file
        #
        # To compensate for these cases, we walk up the directory hierarchy
        # from the given file and try to match a <gem-name.gemspec> file in
        # one of those folders to see if the path really belongs in the given gem
        # or not.
        return false unless Bundler::Source::Git === @spec.source

        parent = Pathname.new(path)

        until parent.root?
          parent = parent.parent.expand_path
          return true if parent.join("#{name}.gemspec").file?
        end

        false
      end

      sig { returns(T::Boolean) }
      def gem_ignored?
        IGNORED_GEMS.include?(name)
      end
    end
  end
end

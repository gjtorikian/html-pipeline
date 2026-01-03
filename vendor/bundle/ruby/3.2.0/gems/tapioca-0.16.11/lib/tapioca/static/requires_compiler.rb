# typed: strict
# frozen_string_literal: true

module Tapioca
  module Static
    class RequiresCompiler
      extend T::Sig

      sig { params(sorbet_path: String).void }
      def initialize(sorbet_path)
        @sorbet_path = sorbet_path
      end

      sig { returns(String) }
      def compile
        config = Spoom::Sorbet::Config.parse_file(@sorbet_path)
        files = collect_files(config)
        names_in_project = files.to_h { |file| [File.basename(file, ".rb"), true] }
        files.flat_map do |file|
          collect_requires(file).reject { |req| names_in_project[req] }
        end.sort.uniq.map do |name|
          "require \"#{name}\"\n"
        end.join
      end

      private

      sig { params(config: Spoom::Sorbet::Config).returns(T::Array[String]) }
      def collect_files(config)
        config.paths.flat_map do |path|
          path = (Pathname.new(@sorbet_path) / "../.." / path).cleanpath
          if path.directory?
            Dir.glob("#{path}/**/*.rb", File::FNM_EXTGLOB).reject do |file|
              relative_file_path = Pathname.new(file).relative_path_from(path)
              file_ignored_by_sorbet?(config, relative_file_path)
            end
          else
            [path.to_s]
          end
        end.sort.uniq
      end

      sig { params(file_path: String).returns(T::Enumerable[String]) }
      def collect_requires(file_path)
        File.binread(file_path).lines.filter_map do |line|
          /^\s*require\s*(\(\s*)?['"](?<name>[^'"]+)['"](\s*\))?/.match(line) { |m| m["name"] }
        end.reject { |require| require.include?('#{') } # ignore interpolation
      end

      sig { params(config: Spoom::Sorbet::Config, file_path: Pathname).returns(T::Boolean) }
      def file_ignored_by_sorbet?(config, file_path)
        file_path_parts = path_parts(file_path)

        config.ignore.any? do |ignore|
          # Sorbet --ignore matching method:
          # ---
          # Ignores input files that contain the given
          # string in their paths (relative to the input
          # path passed to Sorbet).
          #
          # Strings beginning with / match against the
          # prefix of these relative paths; others are
          # substring matches.

          # Matches must be against whole folder and file
          # names, so `foo` matches `/foo/bar.rb` and
          # `/bar/foo/baz.rb` but not `/foo.rb` or
          # `/foo2/bar.rb`.
          ignore_parts = path_parts(Pathname.new(ignore))
          file_path_part_sequences = file_path_parts.each_cons(ignore_parts.size)
          # if ignore string begins with /, we only want the first sequence to match
          file_path_part_sequences = [file_path_part_sequences.first].to_enum if ignore.start_with?("/")

          # we need to match whole segments
          file_path_part_sequences.include?(ignore_parts)
        end
      end

      sig { params(path: Pathname).returns(T::Array[String]) }
      def path_parts(path)
        T.unsafe(path).descend.map { |part| part.basename.to_s }
      end
    end
  end
end

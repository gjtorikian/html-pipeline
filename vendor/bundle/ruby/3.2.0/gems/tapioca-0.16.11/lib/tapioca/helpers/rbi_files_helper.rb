# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBIFilesHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Thor::Shell }
    requires_ancestor { SorbetHelper }

    sig { params(index: RBI::Index, kind: String, file: String).void }
    def index_rbi(index, kind, file)
      return unless File.exist?(file)

      say("Loading #{kind} RBIs from #{file}... ")
      time = Benchmark.realtime do
        parse_and_index_files(index, [file], number_of_workers: 1)
      end
      say(" Done ", :green)
      say("(#{time.round(2)}s)")
    end

    sig { params(index: RBI::Index, kind: String, dir: String, number_of_workers: T.nilable(Integer)).void }
    def index_rbis(index, kind, dir, number_of_workers:)
      return unless Dir.exist?(dir) && !Dir.empty?(dir)

      if kind == "payload"
        say("Loading Sorbet payload... ")
      else
        say("Loading #{kind} RBIs from #{dir}... ")
      end
      time = Benchmark.realtime do
        files = Dir.glob("#{dir}/**/*.rbi").sort
        parse_and_index_files(index, files, number_of_workers: number_of_workers)
      end
      say(" Done ", :green)
      say("(#{time.round(2)}s)")
    end

    sig do
      params(
        index: RBI::Index,
        shim_rbi_dir: String,
        todo_rbi_file: String,
      ).returns(T::Hash[String, T::Array[RBI::Node]])
    end
    def duplicated_nodes_from_index(index, shim_rbi_dir:, todo_rbi_file:)
      duplicates = {}
      say("Looking for duplicates... ")
      time = Benchmark.realtime do
        index.keys.each do |key|
          nodes = index[key]
          next unless shims_or_todos_have_duplicates?(nodes, shim_rbi_dir: shim_rbi_dir, todo_rbi_file: todo_rbi_file)

          duplicates[key] = nodes
        end
      end
      say(" Done ", :green)
      say("(#{time.round(2)}s)")
      duplicates
    end

    sig { params(loc: RBI::Loc, path_prefix: T.nilable(String)).returns(String) }
    def location_to_payload_url(loc, path_prefix:)
      return loc.to_s unless path_prefix

      url = loc.file || ""
      return loc.to_s unless url.start_with?(path_prefix)

      url = url.sub(path_prefix, SorbetHelper::SORBET_PAYLOAD_URL)
      url = "#{url}#L#{loc.begin_line}"
      url
    end

    sig do
      params(
        command: String,
        gem_dir: String,
        dsl_dir: String,
        auto_strictness: T::Boolean,
        gems: T::Array[Gemfile::GemSpec],
        compilers: T::Enumerable[T.class_of(Dsl::Compiler)],
      ).void
    end
    def validate_rbi_files(command:, gem_dir:, dsl_dir:, auto_strictness:, gems: [], compilers: [])
      error_url_base = Spoom::Sorbet::Errors::DEFAULT_ERROR_URL_BASE

      say("Checking generated RBI files... ")
      res = sorbet(
        "--no-config",
        "--error-url-base=#{error_url_base}",
        "--stop-after namer",
        dsl_dir,
        gem_dir,
      )
      say(" Done", :green)

      errors = Spoom::Sorbet::Errors::Parser.parse_string(res.err || "")

      if errors.empty?
        say("  No errors found\n\n", [:green, :bold])

        return
      end

      parse_errors = errors.select { |error| error.code < 4000 }

      error_messages = []

      if parse_errors.any?
        error_messages << set_color(<<~ERR, :red)
          ##### INTERNAL ERROR #####

          There are parse errors in the generated RBI files.

          This seems related to a bug in Tapioca.
          Please open an issue at https://github.com/Shopify/tapioca/issues/new with the following information:

          Tapioca v#{Tapioca::VERSION}

          Command:
            #{command}
        ERR

        error_messages << set_color(<<~ERR, :red) if gems.any?
          Gems:
          #{gems.map { |gem| "  #{gem.name} (#{gem.version})" }.join("\n")}
        ERR

        error_messages << set_color(<<~ERR, :red) if compilers.any?
          Compilers:
          #{compilers.map { |compiler| "  #{compiler.name}" }.join("\n")}
        ERR

        error_messages << set_color(<<~ERR, :red)
          Errors:
          #{parse_errors.map { |error| "  #{error}" }.join("\n")}

          ##########################
        ERR
      end

      if auto_strictness
        redef_errors = errors.select { |error| error.code == 4010 }
        update_gem_rbis_strictnesses(redef_errors, gem_dir)
      end

      Kernel.raise Thor::Error, error_messages.join("\n") if parse_errors.any?
    end

    private

    sig { params(index: RBI::Index, files: T::Array[String], number_of_workers: T.nilable(Integer)).void }
    def parse_and_index_files(index, files, number_of_workers:)
      executor = Executor.new(files, number_of_workers: number_of_workers)

      trees = executor.run_in_parallel do |file|
        next if Spoom::Sorbet::Sigils.file_strictness(file) == "ignore"

        RBI::Parser.parse_file(file)
      rescue RBI::ParseError => e
        say_error("\nWarning: #{e} (#{e.location})", :yellow)
        nil
      end.compact

      index.visit_all(trees)
    end

    sig { params(nodes: T::Array[RBI::Node], shim_rbi_dir: String, todo_rbi_file: String).returns(T::Boolean) }
    def shims_or_todos_have_duplicates?(nodes, shim_rbi_dir:, todo_rbi_file:)
      return false if nodes.size == 1

      shims_or_todos = extract_shims_and_todos(nodes, shim_rbi_dir: shim_rbi_dir, todo_rbi_file: todo_rbi_file)
      return false if shims_or_todos.empty?

      not_shims_or_todos = nodes - shims_or_todos
      shims_or_todos_empty_scopes = extract_empty_scopes(shims_or_todos)

      # We need to discard classes that are redefining the parent of a class
      shims_or_todos_empty_scopes.select! do |scope|
        # Empty modules are always duplicates
        next true unless scope.is_a?(RBI::Class)

        # Empty classes without parents are also duplicates
        parent_name = scope.superclass_name
        next true unless parent_name

        # Empty classes that are not redefining the parent are also duplicates
        not_shims_or_todos.any? { |node| node.is_a?(RBI::Class) && node.superclass_name == parent_name }
      end
      return true unless shims_or_todos_empty_scopes.empty?

      mixins = extract_mixins(shims_or_todos)
      return true unless mixins.empty?

      props = extract_methods_and_attrs(shims_or_todos)
      return false if props.empty?

      shims_or_todos_with_sigs = extract_nodes_with_sigs(props)
      shims_or_todos_with_sigs.each do |shim_or_todo|
        shims_or_todos_sigs = shim_or_todo.sigs

        extract_methods_and_attrs(nodes).each do |node|
          next if node == shim_or_todo
          return true if shims_or_todos_sigs.all? { |sig| node.sigs.include?(sig) }
        end

        return false
      end

      true
    end

    sig { params(nodes: T::Array[RBI::Node], shim_rbi_dir: String, todo_rbi_file: String).returns(T::Array[RBI::Node]) }
    def extract_shims_and_todos(nodes, shim_rbi_dir:, todo_rbi_file:)
      nodes.select do |node|
        node.loc&.file&.start_with?(shim_rbi_dir) || node.loc&.file == todo_rbi_file
      end
    end

    sig { params(nodes: T::Array[RBI::Node]).returns(T::Array[RBI::Scope]) }
    def extract_empty_scopes(nodes)
      T.cast(nodes.select { |node| node.is_a?(RBI::Scope) && node.empty? }, T::Array[RBI::Scope])
    end

    sig { params(nodes: T::Array[RBI::Node]).returns(T::Array[T.any(RBI::Method, RBI::Attr)]) }
    def extract_methods_and_attrs(nodes)
      T.cast(
        nodes.select do |node|
          node.is_a?(RBI::Method) || node.is_a?(RBI::Attr)
        end,
        T::Array[T.any(RBI::Method, RBI::Attr)],
      )
    end

    sig { params(nodes: T::Array[RBI::Node]).returns(T::Array[T.any(RBI::Mixin, RBI::RequiresAncestor)]) }
    def extract_mixins(nodes)
      T.cast(
        nodes.select do |node|
          node.is_a?(RBI::Mixin) || node.is_a?(RBI::RequiresAncestor)
        end,
        T::Array[T.all(RBI::Mixin, RBI::RequiresAncestor)],
      )
    end

    sig { params(nodes: T::Array[T.any(RBI::Method, RBI::Attr)]).returns(T::Array[T.any(RBI::Method, RBI::Attr)]) }
    def extract_nodes_with_sigs(nodes)
      nodes.reject { |node| node.sigs.empty? }
    end

    sig { params(errors: T::Array[Spoom::Sorbet::Errors::Error], gem_dir: String).void }
    def update_gem_rbis_strictnesses(errors, gem_dir)
      files = []

      errors.each do |error|
        # Collect the file with error
        files << error.file
        error.more.each do |line|
          # Also collect the conflicting definition file paths
          next unless line.include?("Previous definition")

          files << line.split(":").first&.strip
        end
      end

      files
        .uniq
        .sort
        .select { |file| file.start_with?(gem_dir) }
        .each do |file|
          Spoom::Sorbet::Sigils.change_sigil_in_file(file, "false")
          say("\n  Changed strictness of #{file} to `typed: false` (conflicting with DSL files)", [:yellow, :bold])
        end

      say("\n")
    end

    sig { params(path: String).returns(String) }
    def gem_name_from_rbi_path(path)
      T.must(File.basename(path, ".rbi").split("@").first)
    end
  end
end

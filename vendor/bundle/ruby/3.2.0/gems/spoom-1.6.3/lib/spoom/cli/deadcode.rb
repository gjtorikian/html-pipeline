# typed: true
# frozen_string_literal: true

require_relative "../deadcode"

module Spoom
  module Cli
    class Deadcode < Thor
      include Helper

      default_task :deadcode

      desc "deadcode PATH...", "Analyze PATHS to find dead code"
      option :allowed_extensions,
        type: :array,
        default: [".rb", ".erb", ".gemspec"],
        aliases: :e,
        desc: "Allowed extensions"
      option :allowed_mime_types,
        type: :array,
        default: ["text/x-ruby", "text/x-ruby-script"],
        aliases: :m,
        desc: "Allowed mime types"
      option :exclude,
        type: :array,
        default: ["vendor/", "sorbet/", "tmp/", "log/", "node_modules/"],
        aliases: :x,
        desc: "Exclude paths"
      option :show_files,
        type: :boolean,
        default: false,
        desc: "Show the files that will be analyzed"
      option :show_plugins,
        type: :boolean,
        default: false,
        desc: "Show the loaded plugins"
      option :show_defs,
        type: :boolean,
        default: false,
        desc: "Show the indexed definitions"
      option :show_refs,
        type: :boolean,
        default: false,
        desc: "Show the indexed references"
      option :sort,
        type: :string,
        default: "name",
        enum: ["name", "location"],
        desc: "Sort the output by name or location"
      #: (*String paths) -> void
      def deadcode(*paths)
        context = self.context

        paths << exec_path if paths.empty?

        $stderr.puts "Collecting files..."
        collector = FileCollector.new(
          allow_extensions: options[:allowed_extensions],
          allow_mime_types: options[:allowed_mime_types],
          exclude_patterns: paths.flat_map do |path|
            options[:exclude].map { |excluded| Pathname.new(File.join(path, excluded, "**")).cleanpath.to_s }
          end,
        )
        collector.visit_paths(paths)
        files = collector.files.sort

        if options[:show_files]
          $stderr.puts "\nCollected #{blue(files.size.to_s)} files for analysis\n"
          files.each do |file|
            $stderr.puts "  #{gray(file)}"
          end
          $stderr.puts
        end

        plugin_classes = Spoom::Deadcode.plugins_from_gemfile_lock(context)
        plugin_classes.merge(Spoom::Deadcode.load_custom_plugins(context))
        if options[:show_plugins]
          $stderr.puts "\nLoaded #{blue(plugin_classes.size.to_s)} plugins\n"
          plugin_classes.each do |plugin|
            $stderr.puts "  #{gray(plugin.to_s)}"
          end
          $stderr.puts
        end

        model = Spoom::Model.new
        index = Spoom::Deadcode::Index.new(model)
        plugins = plugin_classes.map { |plugin| plugin.new(index) }

        $stderr.puts "Indexing #{blue(files.size.to_s)} files..."
        files.each do |file|
          index.index_file(file, plugins: plugins)
        rescue ParseError => e
          say_error("Error parsing #{file}: #{e.message}")
          next
        rescue Spoom::Deadcode::Index::Error => e
          say_error("Error indexing #{file}: #{e.message}")
          next
        end

        model.finalize!
        index.apply_plugins!(plugins)
        index.finalize!

        if options[:show_defs]
          $stderr.puts "\nDefinitions:"
          index.definitions.each do |name, definitions|
            $stderr.puts "  #{blue(name)}"
            definitions.each do |definition|
              $stderr.puts "    #{yellow(definition.kind.serialize)} #{gray(definition.location.to_s)}"
            end
          end
          $stderr.puts
        end

        if options[:show_refs]
          $stderr.puts "\nReferences:"
          index.references.values.flatten.sort_by(&:name).each do |references|
            name = references.name
            kind = references.kind.serialize
            loc = references.location.to_s
            $stderr.puts "  #{blue(name)} #{yellow(kind)} #{gray(loc)}"
          end
          $stderr.puts
        end

        definitions_count = index.definitions.size.to_s
        references_count = index.references.size.to_s
        $stderr.puts "Analyzing #{blue(definitions_count)} definitions against #{blue(references_count)} references..."

        dead = index.definitions.values.flatten.select(&:dead?)

        if options[:sort] == "name"
          dead.sort_by!(&:name)
        else
          dead.sort_by!(&:location)
        end

        if dead.empty?
          $stderr.puts "\n#{green("No dead code found!")}"
        else
          $stderr.puts "\nCandidates:"
          dead.each do |definition|
            $stderr.puts "  #{red(definition.full_name)} #{gray(definition.location.to_s)}"
          end
          $stderr.puts "\n"
          $stderr.puts red("  Found #{dead.size} dead candidates")

          exit(1)
        end
      end

      desc "remove LOCATION", "Remove dead code at LOCATION"
      def remove(location_string)
        location = Location.from_string(location_string)
        context = self.context
        remover = Spoom::Deadcode::Remover.new(context)

        new_source = remover.remove_location(nil, location)
        context.write!("PATCH", new_source)

        diff = context.exec("diff -u #{location.file} PATCH")
        $stderr.puts T.must(diff.out.lines[2..-1]).join
        context.remove!("PATCH")

        context.write!(location.file, new_source)
      rescue Spoom::Deadcode::Remover::Error => e
        say_error("Can't remove code at #{location_string}: #{e.message}")
        exit(1)
      rescue Location::LocationError => e
        say_error(e.message)
        exit(1)
      end
    end
  end
end

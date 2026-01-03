# typed: true
# frozen_string_literal: true

module Tapioca
  class Cli < Thor
    include CliHelper
    include ConfigHelper
    include EnvHelper

    FILE_HEADER_OPTION_DESC = "Add a \"This file is generated\" header on top of each generated RBI file"

    check_unknown_options!

    class_option :config,
      aliases: ["-c"],
      banner: "<config file path>",
      type: :string,
      desc: "Path to the Tapioca configuration file",
      default: TAPIOCA_CONFIG_FILE
    class_option :verbose,
      aliases: ["-V"],
      type: :boolean,
      desc: "Verbose output for debugging purposes",
      default: false

    desc "init", "Get project ready for type checking"
    def init
      # We need to make sure that trackers stay enabled until the `gem` command is invoked
      Runtime::Trackers.with_trackers_enabled do
        invoke(:configure)
        invoke(:annotations)
        invoke(:gem)
      end

      # call the command directly to skip deprecation warning
      Commands::Todo.new(
        todo_file: DEFAULT_TODO_FILE,
        file_header: true,
      ).run

      print_init_next_steps
    end

    desc "configure", "Initialize folder structure and type checking configuration"
    option :postrequire, type: :string, default: DEFAULT_POSTREQUIRE_FILE
    def configure
      command = Commands::Configure.new(
        sorbet_config: SORBET_CONFIG_FILE,
        tapioca_config: options[:config],
        default_postrequire: options[:postrequire],
      )
      command.run
    end

    desc "require", "Generate the list of files to be required by tapioca"
    option :postrequire, type: :string, default: DEFAULT_POSTREQUIRE_FILE
    def require
      command = Commands::Require.new(
        requires_path: options[:postrequire],
        sorbet_config_path: SORBET_CONFIG_FILE,
      )
      command.run
    end

    desc "todo", "Generate the list of unresolved constants"
    option :todo_file,
      type: :string,
      desc: "Path to the generated todo RBI file",
      default: DEFAULT_TODO_FILE
    option :file_header,
      type: :boolean,
      desc: FILE_HEADER_OPTION_DESC,
      default: true
    def todo
      command = Commands::Todo.new(
        todo_file: options[:todo_file],
        file_header: options[:file_header],
      )
      command.run_with_deprecation
    end

    desc "dsl [constant...]", "Generate RBIs for dynamic methods"
    option :outdir,
      aliases: ["--out", "-o"],
      banner: "directory",
      desc: "The output directory for generated DSL RBI files",
      default: DEFAULT_DSL_DIR
    option :file_header,
      type: :boolean,
      desc: FILE_HEADER_OPTION_DESC,
      default: true
    option :only,
      type: :array,
      banner: "compiler [compiler ...]",
      desc: "Only run supplied DSL compiler(s)",
      default: []
    option :exclude,
      type: :array,
      banner: "compiler [compiler ...]",
      desc: "Exclude supplied DSL compiler(s)",
      default: []
    option :verify,
      type: :boolean,
      default: false,
      desc: "Verifies RBIs are up-to-date"
    option :quiet,
      aliases: ["-q"],
      type: :boolean,
      desc: "Suppresses file creation output",
      default: false
    option :workers,
      aliases: ["-w"],
      type: :numeric,
      desc: "Number of parallel workers to use when generating RBIs (default: auto)"
    option :rbi_max_line_length,
      type: :numeric,
      desc: "Set the max line length of generated RBIs. Signatures longer than the max line length will be wrapped",
      default: DEFAULT_RBI_MAX_LINE_LENGTH
    option :environment,
      aliases: ["-e"],
      type: :string,
      desc: "The Rack/Rails environment to use when generating RBIs",
      default: DEFAULT_ENVIRONMENT
    option :list_compilers,
      aliases: ["-l"],
      type: :boolean,
      desc: "List all loaded compilers",
      default: false
    option :app_root,
      type: :string,
      desc: "The path to the Rails application",
      default: "."
    option :halt_upon_load_error,
      type: :boolean,
      desc: "Halt upon a load error while loading the Rails application",
      default: true
    option :skip_constant,
      type: :array,
      banner: "constant [constant ...]",
      desc: "Do not generate RBI definitions for the given application constant(s)",
      default: []
    option :compiler_options,
      type: :hash,
      desc: "Options to pass to the DSL compilers",
      default: {}
    def dsl(*constant_or_paths)
      set_environment(options)

      # Assume anything starting with a capital letter or colon is a class, otherwise a path
      constants, paths = constant_or_paths.partition { |c| c =~ /\A[A-Z:]/ }

      command_args = {
        requested_constants: constants,
        requested_paths: paths.map { |p| Pathname.new(p) },
        outpath: Pathname.new(options[:outdir]),
        only: options[:only],
        exclude: options[:exclude],
        file_header: options[:file_header],
        tapioca_path: TAPIOCA_DIR,
        skip_constant: options[:skip_constant],
        quiet: options[:quiet],
        verbose: options[:verbose],
        number_of_workers: options[:workers],
        rbi_formatter: rbi_formatter(options),
        app_root: options[:app_root],
        halt_upon_load_error: options[:halt_upon_load_error],
        compiler_options: options[:compiler_options],
        lsp_addon: self.class.addon_mode,
      }

      command = if options[:verify]
        Commands::DslVerify.new(**command_args)
      elsif options[:list_compilers]
        Commands::DslCompilerList.new(**command_args)
      else
        Commands::DslGenerate.new(**command_args)
      end

      command.run
    end

    desc "gem [gem...]", "Generate RBIs from gems"
    option :outdir,
      aliases: ["--out", "-o"],
      banner: "directory",
      desc: "The output directory for generated gem RBI files",
      default: DEFAULT_GEM_DIR
    option :file_header,
      type: :boolean,
      desc: FILE_HEADER_OPTION_DESC,
      default: true
    option :all,
      type: :boolean,
      desc: "Regenerate RBI files for all gems",
      default: false
    option :prerequire,
      aliases: ["--pre", "-b"],
      banner: "file",
      desc: "A file to be required before Bundler.require is called",
      default: nil
    option :postrequire,
      aliases: ["--post", "-a"],
      banner: "file",
      desc: "A file to be required after Bundler.require is called",
      default: DEFAULT_POSTREQUIRE_FILE
    option :exclude,
      aliases: ["-x"],
      type: :array,
      banner: "gem [gem ...]",
      desc: "Exclude the given gem(s) from RBI generation",
      default: []
    option :include_dependencies,
      type: :boolean,
      desc: "Generate RBI files for dependencies of the given gem(s)",
      default: false
    option :typed_overrides,
      aliases: ["--typed", "-t"],
      type: :hash,
      banner: "gem:level [gem:level ...]",
      desc: "Override for typed sigils for generated gem RBIs",
      default: DEFAULT_OVERRIDES
    option :verify,
      type: :boolean,
      desc: "Verify RBIs are up-to-date",
      default: false
    option :doc,
      type: :boolean,
      desc: "Include YARD documentation from sources when generating RBIs. Warning: this might be slow",
      default: true
    option :loc,
      type: :boolean,
      desc: "Include comments with source location when generating RBIs",
      default: true
    option :exported_gem_rbis,
      type: :boolean,
      desc: "Include RBIs found in the `rbi/` directory of the gem",
      default: true
    option :workers,
      aliases: ["-w"],
      type: :numeric,
      desc: "Number of parallel workers to use when generating RBIs (default: auto)"
    option :auto_strictness,
      type: :boolean,
      desc: "Autocorrect strictness in gem RBIs in case of conflict with the DSL RBIs",
      default: true
    option :dsl_dir,
      aliases: ["--dsl-dir"],
      banner: "directory",
      desc: "The DSL directory used to correct gems strictnesses",
      default: DEFAULT_DSL_DIR
    option :rbi_max_line_length,
      type: :numeric,
      desc: "Set the max line length of generated RBIs. Signatures longer than the max line length will be wrapped",
      default: DEFAULT_RBI_MAX_LINE_LENGTH
    option :environment,
      aliases: ["-e"],
      type: :string,
      desc: "The Rack/Rails environment to use when generating RBIs",
      default: DEFAULT_ENVIRONMENT
    option :halt_upon_load_error,
      type: :boolean,
      desc: "Halt upon a load error while loading the Rails application",
      default: true
    option :lsp_addon,
      type: :boolean,
      desc: "Generate Gem RBIs from the LSP add-on. Internal to Tapioca and not intended for end-users",
      default: false,
      hide: true
    def gem(*gems)
      set_environment(options)

      all = options[:all]
      verify = options[:verify]
      include_dependencies = options[:include_dependencies]

      raise MalformattedArgumentError, "Options '--all' and '--verify' are mutually exclusive" if all && verify

      if gems.empty?
        raise MalformattedArgumentError,
          "Option '--include-dependencies' must be provided with gems" if include_dependencies
      else
        raise MalformattedArgumentError, "Option '--all' must be provided without any other arguments" if all
        raise MalformattedArgumentError, "Option '--verify' must be provided without any other arguments" if verify
      end

      command_args = {
        gem_names: all ? [] : gems,
        exclude: options[:exclude],
        include_dependencies: options[:include_dependencies],
        prerequire: options[:prerequire],
        postrequire: options[:postrequire],
        typed_overrides: options[:typed_overrides],
        outpath: Pathname.new(options[:outdir]),
        file_header: options[:file_header],
        include_doc: options[:doc],
        include_loc: options[:loc],
        include_exported_rbis: options[:exported_gem_rbis],
        number_of_workers: options[:workers],
        auto_strictness: options[:auto_strictness],
        dsl_dir: options[:dsl_dir],
        rbi_formatter: rbi_formatter(options),
        halt_upon_load_error: options[:halt_upon_load_error],
        lsp_addon: options[:lsp_addon],
      }

      command = if verify
        Commands::GemVerify.new(**command_args)
      elsif !gems.empty? || all
        Commands::GemGenerate.new(**command_args)
      else
        Commands::GemSync.new(**command_args)
      end

      command.run
    end
    map "gems" => :gem

    desc "check-shims", "Check duplicated definitions in shim RBIs"
    option :gem_rbi_dir, type: :string, desc: "Path to gem RBIs", default: DEFAULT_GEM_DIR
    option :dsl_rbi_dir, type: :string, desc: "Path to DSL RBIs", default: DEFAULT_DSL_DIR
    option :shim_rbi_dir, type: :string, desc: "Path to shim RBIs", default: DEFAULT_SHIM_DIR
    option :annotations_rbi_dir, type: :string, desc: "Path to annotations RBIs", default: DEFAULT_ANNOTATIONS_DIR
    option :todo_rbi_file, type: :string, desc: "Path to the generated todo RBI file", default: DEFAULT_TODO_FILE
    option :payload, type: :boolean, desc: "Check shims against Sorbet's payload", default: true
    option :workers, aliases: ["-w"], type: :numeric, desc: "Number of parallel workers (default: auto)"
    def check_shims
      command = Commands::CheckShims.new(
        gem_rbi_dir: options[:gem_rbi_dir],
        dsl_rbi_dir: options[:dsl_rbi_dir],
        shim_rbi_dir: options[:shim_rbi_dir],
        annotations_rbi_dir: options[:annotations_rbi_dir],
        todo_rbi_file: options[:todo_rbi_file],
        payload: options[:payload],
        number_of_workers: options[:workers],
      )

      command.run
    end

    desc "annotations", "Pull gem RBI annotations from remote sources"
    option :sources,
      type: :array,
      default: [CENTRAL_REPO_ROOT_URI],
      desc: "URIs of the sources to pull gem RBI annotations from"
    option :netrc, type: :boolean, default: true, desc: "Use .netrc to authenticate to private sources"
    option :netrc_file, type: :string, desc: "Path to .netrc file"
    option :auth, type: :string, default: nil, desc: "HTTP authorization header for private sources"
    option :typed_overrides,
      aliases: ["--typed", "-t"],
      type: :hash,
      banner: "gem:level [gem:level ...]",
      desc: "Override for typed sigils for pulled annotations",
      default: {}
    def annotations
      if !options[:netrc] && options[:netrc_file]
        raise Thor::Error, set_color("Options `--no-netrc` and `--netrc-file` can't be used together", :bold, :red)
      end

      command = Commands::Annotations.new(
        central_repo_root_uris: options[:sources],
        auth: options[:auth],
        netrc_file: netrc_file(options),
        typed_overrides: options[:typed_overrides],
      )

      command.run
    end

    map ["--version", "-v"] => :__print_version

    desc "--version, -v", "Show version"
    def __print_version
      puts "Tapioca v#{Tapioca::VERSION}"
    end

    no_commands do
      @addon_mode = false

      class << self
        extend T::Sig

        # Indicates that we are running from the LSP, set using the `addon_mode!` method
        attr_reader :addon_mode

        sig { void }
        def addon_mode!
          @addon_mode = true
        end

        sig { returns(T::Boolean) }
        def exit_on_failure?
          !@addon_mode
        end
      end
    end

    private

    def print_init_next_steps
      say(<<~OUTPUT)
        #{set_color("This project is now set up for use with Sorbet and Tapioca", :bold)}

        The sorbet/ folder should exist and look something like this:

        ├── config             # Default options to be passed to Sorbet on every run
        └── rbi/
          ├── annotations/     # Type definitions pulled from the rbi-central repository
          ├── gems/            # Autogenerated type definitions for your gems
          └── todo.rbi         # Constants which were still missing after RBI generation
        └── tapioca/
          ├── config.yml       # Default options to be passed to Tapioca
          └── require.rb       # A file where you can make requires from gems that might be needed for gem RBI generation

        Please check this folder into version control.

        #{set_color("🤔 What's next", :bold)}

        1. Many Ruby applications use metaprogramming DSLs to dynamically generate constants and methods.
          To generate type definitions for any DSLs in your application, run:

          #{set_color("bin/tapioca dsl", :cyan)}

        2. Check whether the constants in the #{set_color("sorbet/rbi/todo.rbi", :cyan)} file actually exist in your project.
          It is possible that some of these constants are typos, and leaving them in #{set_color("todo.rbi", :cyan)} will
          hide errors in your application. Ideally, you should be able to remove all definitions
          from this file and delete it.

        3. Typecheck your project:

          #{set_color("bundle exec srb tc", :cyan)}

          There should not be any typechecking errors.

        4. Upgrade a file marked "#{set_color("# typed: false", :cyan)}" to "#{set_color("# typed: true", :cyan)}".
          Then, run: #{set_color("bundle exec srb tc", :cyan)} and try to fix any errors.

          You can use Spoom to bump files for you:

          #{set_color("spoom bump --from false --to true", :cyan)}

          To learn more about Spoom, visit: #{set_color("https://github.com/Shopify/spoom", :cyan)}

        5. Add signatures to your methods with #{set_color("sig", :cyan)}. To learn how, read: #{set_color("https://sorbet.org/docs/sigs", :cyan)}

        #{set_color("Documentation", :bold)}
        We recommend skimming these docs to get a feel for how to use Sorbet:
        - Gradual Type Checking: #{set_color("https://sorbet.org/docs/gradual", :cyan)}
        - Enabling Static Checks: #{set_color("https://sorbet.org/docs/static", :cyan)}
        - RBI Files: #{set_color("https://sorbet.org/docs/rbi", :cyan)}
      OUTPUT
    end
  end
end

# typed: true
# frozen_string_literal: true

require "spoom/sorbet/sigs"

module Spoom
  module Cli
    module Srb
      class Sigs < Thor
        include Helper

        desc "translate", "Translate signatures from/to RBI and RBS"
        option :from, type: :string, aliases: :f, desc: "From format", enum: ["rbi", "rbs"], default: "rbi"
        option :to, type: :string, aliases: :t, desc: "To format", enum: ["rbi", "rbs"], default: "rbs"
        option :positional_names,
          type: :boolean,
          aliases: :p,
          desc: "Use positional names when translating from RBI to RBS",
          default: true
        option :include_rbi_files, type: :boolean, desc: "Include RBI files", default: false
        def translate(*paths)
          from = options[:from]
          to = options[:to]

          if from == to
            say_error("Can't translate signatures from `#{from}` to `#{to}`")
            exit(1)
          end

          files = collect_files(paths, include_rbi_files: options[:include_rbi_files])

          say("Translating signatures from `#{from}` to `#{to}` " \
            "in `#{files.size}` file#{files.size == 1 ? "" : "s"}...\n\n")

          case from
          when "rbi"
            transformed_files = transform_files(files) do |_file, contents|
              Spoom::Sorbet::Sigs.rbi_to_rbs(contents, positional_names: options[:positional_names])
            end
          when "rbs"
            transformed_files = transform_files(files) do |_file, contents|
              Spoom::Sorbet::Sigs.rbs_to_rbi(contents)
            end
          end

          say("Translated signatures in `#{transformed_files}` file#{transformed_files == 1 ? "" : "s"}.")
        end

        desc "strip", "Strip all the signatures from the files"
        def strip(*paths)
          files = collect_files(paths)

          say("Stripping signatures from `#{files.size}` file#{files.size == 1 ? "" : "s"}...\n\n")

          transformed_files = transform_files(files) do |_file, contents|
            Spoom::Sorbet::Sigs.strip(contents)
          end

          say("Stripped signatures from `#{transformed_files}` file#{transformed_files == 1 ? "" : "s"}.")
        end

        # Extract signatures from gem's files and save them to the output file
        #
        # This command will use Tapioca to generate a `.rbi` file that contains the signatures of all the files listed
        # in the gemspec.
        desc "export", "Export gem files signatures"
        option :gemspec, type: :string, desc: "Path to the gemspec file", optional: true, default: nil
        option :check_sync, type: :boolean, desc: "Check the generated RBI is up to date", default: false
        def export(output_path = nil)
          gemspec = options[:gemspec]

          unless gemspec
            say("Locating gemspec file...")
            gemspec = Dir.glob("*.gemspec").first
            unless gemspec
              say_error("No gemspec file found")
              exit(1)
            end
            say("Using `#{gemspec}` as gemspec file")
          end

          spec = Gem::Specification.load(gemspec)

          # First, we copy the files to a temporary directory so we can rewrite them without messing with the
          # original ones.
          say("Copying files to a temporary directory...")
          copy_context = Spoom::Context.mktmp!
          FileUtils.cp_r(
            ["Gemfile", "Gemfile.lock", gemspec, "lib/"],
            copy_context.absolute_path,
          )

          # Then, we transform the copied files to translate all the RBS signatures into RBI signatures.
          say("Translating signatures from RBS to RBI...")
          files = collect_files([copy_context.absolute_path])
          transform_files(files) do |_file, contents|
            Spoom::Sorbet::Sigs.rbs_to_rbi(contents)
          end

          # We need to inject `extend T::Sig` to be sure all the classes can run the `sig{}` blocks.
          # For this we find the entry point of the gem and inject the `extend T::Sig` line at the top of the file.
          entry_point = "lib/#{spec.name}.rb"
          unless copy_context.file?(entry_point)
            say_error("No entry point found at `#{entry_point}`")
            exit(1)
          end

          say("Injecting `extend T::Sig` to `#{entry_point}`...")
          copy_context.write!(entry_point, <<~RB)
            require "sorbet-runtime"

            class Module; include T::Sig; end
            extend T::Sig

            #{copy_context.read(entry_point)}
          RB

          # Now we create a new context to import our modified gem and run tapioca
          say("Running Tapioca...")
          tapioca_context = Spoom::Context.mktmp!
          tapioca_context.write!("Gemfile", <<~RB)
            source "https://rubygems.org"

            gem "tapioca"
            gem "#{spec.name}", path: "#{copy_context.absolute_path}"
          RB
          exec(tapioca_context, "bundle install")
          exec(tapioca_context, "bundle exec tapioca gem #{spec.name} --no-doc --no-loc --no-file-header")

          rbi_path = tapioca_context.glob("sorbet/rbi/gems/#{spec.name}@*.rbi").first
          unless rbi_path && tapioca_context.file?(rbi_path)
            say_error("No RBI file found at `sorbet/rbi/gems/#{spec.name}@*.rbi`")
            exit(1)
          end

          tapioca_context.write!(rbi_path, tapioca_context.read(rbi_path).gsub(/^# typed: true/, <<~RB.rstrip))
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for types exported from the `#{spec.name}` gem.
            # Please instead update this file by running `spoom srb sigs export`.
          RB

          output_path ||= "rbi/#{spec.name}.rbi"
          generated_path = tapioca_context.absolute_path_to(rbi_path)

          if options[:check_sync]
            # If the check option is set, we just compare the generated RBI with the one in the gem.
            # If they are different, we exit with a non-zero exit code.
            unless system("diff -u -L 'generated' -L 'current' #{generated_path} #{output_path} >&2")
              say_error(<<~ERR, status: "\nError")
                The RBI file at `#{output_path}` is not up to date

                Please run `spoom srb sigs export` to update it.
              ERR
              exit(1)
            end

            say("The RBI file at `#{output_path}` is up to date")
            exit(0)
          else
            output_dir = File.dirname(output_path)
            FileUtils.rm_rf(output_dir)
            FileUtils.mkdir_p(output_dir)
            FileUtils.cp(generated_path, output_path)

            say("Exported signatures to `#{output_path}`")
          end
        ensure
          copy_context&.destroy!
          tapioca_context&.destroy!
        end

        no_commands do
          def transform_files(files, &block)
            transformed_count = 0

            files.each do |file|
              contents = File.read(file)
              first_line = contents.lines.first

              if first_line&.start_with?("# encoding:")
                encoding = T.must(first_line).gsub(/^#\s*encoding:\s*/, "").strip
                contents = contents.force_encoding(encoding)
              end

              contents = block.call(file, contents)
              File.write(file, contents)
              transformed_count += 1
            rescue RBI::Error => error
              say_warning("Can't parse #{file}: #{error.message}")
              next
            end

            transformed_count
          end

          def exec(context, command)
            res = context.exec(command)

            unless res.status
              $stderr.puts "Error: #{command} failed"
              $stderr.puts res.err
              exit(1)
            end
          end
        end
      end
    end
  end
end

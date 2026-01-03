# frozen_string_literal: true

require("bundler/gem_tasks")

Dir["tasks/**/*.rake"].each { |t| load t }

require "rubocop/rake_task"
require "rubocop/cop/minitest_generator"

require "minitest/test_task"

Minitest::TestTask.create(:test) do |test|
  test.test_globs = FileList["test/**/*_test.rb"]
end

task(default: [:documentation_syntax_check, :generate_cops_documentation, :test])

desc("Generate a new cop with a template")
task :new_cop, [:cop] do |_task, args|
  require "rubocop"

  cop_name = args.fetch(:cop) do
    warn('usage: bundle exec rake "new_cop[Department/Name]"')
    exit!
  end

  generator = RuboCop::Cop::Generator.new(cop_name)

  generator.write_source
  generator.write_test
  generator.inject_require(root_file_path: "lib/rubocop/cop/sorbet_cops.rb")
  generator.inject_config(config_file_path: "config/default.yml")

  # We don't use Rubocop's changelog automation workflow
  todo_without_changelog_instruction = generator.todo
    .sub(/$\s+4\. Run.*changelog.*for your new cop\.$/m, "")
    .sub(/^  3./, "  3. Run `bundle exec rake generate_cops_documentation` to generate\n     documentation for your new cop.\n  4.")
  puts todo_without_changelog_instruction
end

module Releaser
  extend Rake::DSL
  extend self

  desc "Prepare a release. The version is read from the VERSION file."
  task :prepare_release do
    version = File.read("VERSION").strip
    puts "Preparing release for version #{version}"

    update_file("config/default.yml") do |default|
      default.gsub(/['"]?<<\s*next\s*>>['"]?/i, "'#{version}'")
    end

    sh "bundle install"
    sh "bundle exec rake generate_cops_documentation"

    sh "git add config/default.yml Gemfile.lock VERSION manual"

    sh "git commit -m 'Release v#{version}'"
    sh "git push origin main"
    sh "git tag -a v#{version} -m 'Release v#{version}'"
    sh "git push origin v#{version}"
  end

  private

  def update_file(path)
    content = File.read(path)
    File.write(path, yield(content))
  end
end

desc "Check for stale <<next>> placeholders when VERSION is updated"
task :check_version_placeholders do
  # Check if VERSION file was modified in the last commit
  version_changed = %x(git diff HEAD~1 HEAD --name-only).split("\n").include?("VERSION")

  if version_changed
    puts "VERSION file was updated, checking for stale placeholders..."

    # Check for <<next>> placeholders in config/default.yml
    config_content = File.read("config/default.yml")
    if config_content.match?(/['\"]?<<\s*next\s*>>['\"]?/i)
      puts "\e[31mError: Found stale <<next>> placeholders in config/default.yml after VERSION update!\e[0m"
      puts "\e[31mPlease run 'bundle exec rake prepare_release' to replace placeholders and commit the changes.\e[0m"
      exit 1
    else
      puts "\e[32mNo stale placeholders found - all good!\e[0m"
    end
  else
    puts "VERSION file was not updated in the last commit."
  end
end

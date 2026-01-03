# typed: strict
# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_files = FileList["test/**/*_test.rb"]
end

task(default: :test)

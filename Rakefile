#!/usr/bin/env rake
# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubygems/package_task"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
  t.warning = false
end

task default: :test

require "rubocop/rake_task"

RuboCop::RakeTask.new(:rubocop)

GEMSPEC = Bundler.load_gemspec("html-pipeline.gemspec")
gem_path = Gem::PackageTask.new(GEMSPEC).define
desc "Package the ruby gem"
task "package" => [gem_path]

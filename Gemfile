# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in html-pipeline.gemspec
gemspec

gem "awesome_print"

gem "rubocop"
gem "rubocop-standard"

gem "github_changelog_generator", "~> 1.16"

gem "sorbet-runtime"

group :development, :test do
  gem "amazing_print"
  gem "debug"
end

group :development do
  gem "tapioca", require: false
  gem "sorbet"
  gem "bundler"
  gem "rake"
end

group :test do
  gem "commonmarker", "~> 1.0.0.pre7", require: false
  gem "gemoji", "~> 4.1", require: false
  gem "gemojione", "~> 4.3", require: false

  gem "minitest"

  gem "minitest-bisect", "~> 1.6"

  gem "nokogiri", "~> 1.13"

  gem "minitest-focus", "~> 1.1"
  gem "rouge", "~> 3.1", require: false
end

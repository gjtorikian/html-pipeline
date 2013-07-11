source 'https://rubygems.org'

# Specify your gem's dependencies in html-pipeline.gemspec
gemspec

gem 'activesupport', '< 4.0.0' if RUBY_VERSION < '1.9.3'
gem 'nokogiri',      '< 1.6.0' if RUBY_VERSION < '1.9.2'
gem 'sanitize',      '< 2.0.4' if RUBY_VERSION < '1.9.2'

group :development do
  gem 'bundler'
  gem 'rake'
end

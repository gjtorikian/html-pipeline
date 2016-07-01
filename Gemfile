source "https://rubygems.org"

# Specify your gem's dependencies in html-pipeline.gemspec
gemspec

group :development do
  gem "bundler"
  gem "rake"
  gem "appraisal"
end

group :test do
  gem "minitest"
  gem "rinku",              "~> 1.7",   :require => false
  gem "gemoji",             "~> 2.0",   :require => false
  gem "RedCloth",           "~> 4.2.9", :require => false
  gem "github-markdown",    "~> 0.5",   :require => false
  gem "email_reply_parser", "~> 0.5",   :require => false
  gem "sanitize",           "~> 2.0",   :require => false

  if RUBY_VERSION < "2.1.0"
    gem "escape_utils",     "~> 0.3",   :require => false
    gem "github-linguist",  "~> 2.6.2", :require => false
  else
    gem "escape_utils",     "~> 1.0",   :require => false
    gem "github-linguist",  "~> 2.10",  :require => false
  end

  if RUBY_VERSION < "1.9.3"
    gem "activesupport", ">= 2", "< 4"
  end
end

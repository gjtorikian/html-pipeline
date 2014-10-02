source "https://rubygems.org"

# Specify your gem's dependencies in html-pipeline.gemspec
gemspec

group :development do
  gem "bundler"
  gem "rake"
end

group :test do
  gem "minitest",           "~> 5.0"

  if RUBY_VERSION < "2.1.0"
    gem "escape_utils",     "~> 0.3"
    gem "github-linguist",  "~> 2.6.2"
  else
    gem "escape_utils"
    gem "github-linguist"
  end

  gem "rinku"
  gem "gemoji"
  gem "RedCloth"
  gem "github-markdown"
  gem "email_reply_parser"
  gem "github-linguist"
  gem "sanitize"
  gem "nokogiri"
  gem "activesupport"
end

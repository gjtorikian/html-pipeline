source "https://rubygems.org"

# Specify your gem's dependencies in html-pipeline.gemspec
gemspec

group :development do
  gem "bundler"
  gem "rake"
end

group :test do
  gem "rinku",            "~> 1.7",   :require => false
  gem "gemoji",           "~> 1.0",   :require => false
  gem "RedCloth",         "~> 4.2.9", :require => false
  gem "escape_utils",     "~> 0.3",   :require => false
  gem "github-linguist",  "~> 2.6.2", :require => false
  gem "github-markdown",  "~> 0.5",   :require => false

  if RUBY_VERSION < "1.9.2"
    gem "sanitize", ">= 2", "< 2.0.4", :require => false
  else
    gem "sanitize", "~> 2.0",          :require => false
  end
end

# -*- encoding: utf-8 -*-
require File.expand_path("../lib/html/pipeline/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "html-pipeline"
  gem.version       = HTML::Pipeline::VERSION
  gem.license       = "MIT"
  gem.authors       = ["Ryan Tomayko", "Jerry Cheung"]
  gem.email         = ["ryan@github.com", "jerry@github.com"]
  gem.description   = %q{GitHub HTML processing filters and utilities}
  gem.summary       = %q{Helpers for processing content through a chain of filters}
  gem.homepage      = "https://github.com/jch/html-pipeline"

  gem.files         = `git ls-files`.split $/
  gem.test_files    = gem.files.grep(%r{^test})
  gem.require_paths = ["lib"]

  gem.add_dependency "gemoji",          "~> 1.0"
  gem.add_dependency "nokogiri",        "~> 1.4"
  gem.add_dependency "github-markdown", "~> 0.5"
  gem.add_dependency "sanitize",        "~> 2.0"
  gem.add_dependency "rinku",           "~> 1.7"
  gem.add_dependency "escape_utils",    "~> 0.2"
  gem.add_dependency "activesupport",   ">= 2"

  gem.add_development_dependency "github-linguist", "~> 2.1"
end

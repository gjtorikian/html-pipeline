# -*- encoding: utf-8 -*-
require File.expand_path('../lib/github/html/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jerry Cheung"]
  gem.email         = ["jch@whatcodecraves.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "github-html"
  gem.require_paths = ["lib"]
  gem.version       = GitHub::HTML::VERSION

  gem.add_dependency 'nokogiri',        '~> 1.4'
  gem.add_dependency 'github-markdown', '~> 0.5'
  gem.add_dependency 'sanitize',        '~> 2.0'
  gem.add_dependency 'github-linguist', '~> 2.1'
  gem.add_dependency 'rinku',           '~> 1.7'
  gem.add_dependency 'escape_utils',    '~> 0.2'
  gem.add_dependency 'activesupport'
end

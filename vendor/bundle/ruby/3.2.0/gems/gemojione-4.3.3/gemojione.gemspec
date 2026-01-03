# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gemojione/version'

Gem::Specification.new do |spec|
  spec.name          = "gemojione"
  spec.version       = Gemojione::VERSION
  spec.authors       = ["Steve Klabnik", "Winfield Peterson", "Jonathan Wiesel", "Allan McLelland"]
  spec.email         = ["steve@steveklabnik.com", "winfield.peterson@gmail.com", "jonathanwiesel@gmail.com", "allan@bonus.ly"]
  spec.description   = %q{A gem for EmojiOne}
  spec.summary       = %q{A gem for EmojiOne}
  spec.homepage      = "https://github.com/bonusly/gemojione"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "json"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "sprite-factory"
  spec.add_development_dependency "rmagick"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
end

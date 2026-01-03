# -*- encoding: utf-8 -*-
# stub: rubocop-rails-accessibility 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop-rails-accessibility".freeze
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/github/rubocop-rails-accessibility/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/github/rubocop-rails-accessibility", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/github/rubocop-rails-accessibility" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["GitHub Accessibility Team".freeze]
  s.date = "2024-02-08"
  s.email = ["accessibility@github.com".freeze]
  s.homepage = "https://github.com/github/rubocop-rails-accessibility".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Custom RuboCop rules for Rails Accessibility.".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rubocop>.freeze, [">= 1.0.0"])
  s.add_development_dependency(%q<actionview>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rubocop-github>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0"])
end

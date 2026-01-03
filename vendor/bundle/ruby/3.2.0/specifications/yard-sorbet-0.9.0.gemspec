# -*- encoding: utf-8 -*-
# stub: yard-sorbet 0.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "yard-sorbet".freeze
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/dduugg/yard-sorbet/issues", "changelog_uri" => "https://github.com/dduugg/yard-sorbet/blob/main/CHANGELOG.md", "documentation_uri" => "https://dduugg.github.io/yard-sorbet/", "homepage_uri" => "https://github.com/dduugg/yard-sorbet", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/dduugg/yard-sorbet", "wiki_uri" => "https://github.com/dduugg/yard-sorbet/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Douglas Eichelberger".freeze]
  s.date = "2024-06-30"
  s.description = "A YARD plugin that incorporates Sorbet type information".freeze
  s.email = "dduugg@gmail.com".freeze
  s.homepage = "https://github.com/dduugg/yard-sorbet".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Create YARD docs from Sorbet type signatures".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<sorbet-runtime>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<yard>.freeze, [">= 0"])
end

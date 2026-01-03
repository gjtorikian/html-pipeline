# -*- encoding: utf-8 -*-
# stub: sorbet-runtime 0.6.12872 ruby lib

Gem::Specification.new do |s|
  s.name = "sorbet-runtime".freeze
  s.version = "0.6.12872"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "source_code_uri" => "https://github.com/sorbet/sorbet" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Stripe".freeze]
  s.date = "2025-12-25"
  s.description = "Sorbet's runtime type checking component".freeze
  s.homepage = "https://sorbet.org".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Sorbet runtime".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.11"])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 2.1"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["= 1.81.6"])
  s.add_development_dependency(%q<rubocop-performance>.freeze, ["= 1.13.2"])
  s.add_development_dependency(%q<concurrent-ruby>.freeze, ["~> 1.1.5"])
  s.add_development_dependency(%q<debug>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<subprocess>.freeze, ["~> 1.5.3"])
end

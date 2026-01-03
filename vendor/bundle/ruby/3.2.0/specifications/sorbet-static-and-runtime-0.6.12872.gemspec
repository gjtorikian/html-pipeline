# -*- encoding: utf-8 -*-
# stub: sorbet-static-and-runtime 0.6.12872 ruby lib

Gem::Specification.new do |s|
  s.name = "sorbet-static-and-runtime".freeze
  s.version = "0.6.12872"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "source_code_uri" => "https://github.com/sorbet/sorbet" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Stripe".freeze]
  s.date = "2025-12-25"
  s.description = "Sorbet static and runtime in one gem".freeze
  s.email = "sorbet@stripe.com".freeze
  s.homepage = "https://sorbet.org".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.4.6".freeze
  s.summary = "A Typechecker for Ruby".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<sorbet>.freeze, ["= 0.6.12872"])
  s.add_runtime_dependency(%q<sorbet-runtime>.freeze, ["= 0.6.12872"])
end

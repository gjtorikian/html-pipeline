# -*- encoding: utf-8 -*-
# stub: rbi 0.3.8 ruby lib

Gem::Specification.new do |s|
  s.name = "rbi".freeze
  s.version = "0.3.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alexandre Terrasa".freeze]
  s.date = "2025-12-02"
  s.email = ["ruby@shopify.com".freeze]
  s.homepage = "https://github.com/Shopify/rbi".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.4.6".freeze
  s.summary = "RBI generation framework".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<prism>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<rbs>.freeze, [">= 3.4.4"])
end

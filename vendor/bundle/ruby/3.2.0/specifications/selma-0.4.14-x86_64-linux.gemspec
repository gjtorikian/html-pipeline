# -*- encoding: utf-8 -*-
# stub: selma 0.4.14 x86_64-linux lib

Gem::Specification.new do |s|
  s.name = "selma".freeze
  s.version = "0.4.14"
  s.platform = "x86_64-linux".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 3.4".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "funding_uri" => "https://github.com/sponsors/gjtorikian/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/gjtorikian/selma" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Garen J. Torikian".freeze]
  s.bindir = "exe".freeze
  s.date = "2025-12-03"
  s.email = ["gjtorikian@gmail.com".freeze]
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 3.2".freeze, "< 3.5.dev".freeze])
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Selma selects and matches HTML nodes using CSS rules. Backed by Rust's lol_html parser.".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.2"])
end

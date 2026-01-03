# -*- encoding: utf-8 -*-
# stub: awesome_print 1.9.2 ruby lib

Gem::Specification.new do |s|
  s.name = "awesome_print".freeze
  s.version = "1.9.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Dvorkin".freeze]
  s.date = "2021-03-07"
  s.description = "Great Ruby debugging companion: pretty print Ruby objects to visualize their structure. Supports custom object formatting via plugins".freeze
  s.email = "mike@dvorkin.net".freeze
  s.homepage = "https://github.com/awesome-print/awesome_print".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Pretty print Ruby objects with proper indentation and colors".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, [">= 3.0.0"])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
  s.add_development_dependency(%q<fakefs>.freeze, [">= 0.2.1"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
  s.add_development_dependency(%q<nokogiri>.freeze, [">= 1.11.0"])
end

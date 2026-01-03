# -*- encoding: utf-8 -*-
# stub: gemojione 4.3.3 ruby lib

Gem::Specification.new do |s|
  s.name = "gemojione".freeze
  s.version = "4.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steve Klabnik".freeze, "Winfield Peterson".freeze, "Jonathan Wiesel".freeze, "Allan McLelland".freeze]
  s.date = "2020-06-09"
  s.description = "A gem for EmojiOne".freeze
  s.email = ["steve@steveklabnik.com".freeze, "winfield.peterson@gmail.com".freeze, "jonathanwiesel@gmail.com".freeze, "allan@bonus.ly".freeze]
  s.homepage = "https://github.com/bonusly/gemojione".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.6".freeze
  s.summary = "A gem for EmojiOne".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<sprite-factory>.freeze, [">= 0"])
  s.add_development_dependency(%q<rmagick>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<codeclimate-test-reporter>.freeze, ["~> 1.0.0"])
end

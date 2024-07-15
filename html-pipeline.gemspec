# frozen_string_literal: true

$LOAD_PATH.push(File.expand_path("lib", __dir__))
require "html_pipeline/version"

Gem::Specification.new do |gem|
  gem.name          = "html-pipeline"
  gem.version       = HTMLPipeline::VERSION
  gem.license       = "MIT"
  gem.authors       = ["Garen J. Torikian"]
  gem.email         = ["gjtorikian@gmail.com"]
  gem.description   = "HTML processing filters and utilities"
  gem.summary       = "Helpers for processing content through a chain of filters"
  gem.homepage      = "https://github.com/gjtorikian/html-pipeline"

  gem.files         = %x(git ls-files -z).split("\x0").reject { |f| f =~ %r{^(test|gemfiles|script)/} }
  gem.require_paths = ["lib"]

  gem.required_ruby_version = "~> 3.1"
  # https://github.com/rubygems/rubygems/pull/5852#issuecomment-1231118509
  gem.required_rubygems_version = ">= 3.3.22"

  gem.metadata = {
    "funding_uri" => "https://github.com/sponsors/gjtorikian/",
    "rubygems_mfa_required" => "true",
  }

  gem.add_dependency("selma", "~> 0.4")
  gem.add_dependency("zeitwerk", "~> 2.5")

  gem.post_install_message = <<~MSG
    -------------------------------------------------
    Thank you for installing html-pipeline!
    You must bundle filter gem dependencies.
    See the html-pipeline README.md for more details:
    https://github.com/gjtorikian/html-pipeline#dependencies
    -------------------------------------------------
  MSG
end

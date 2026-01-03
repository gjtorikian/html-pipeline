# frozen_string_literal: true

require_relative "lib/rubocop/sorbet/version"

Gem::Specification.new do |spec|
  spec.name          = "rubocop-sorbet"
  spec.version       = RuboCop::Sorbet::VERSION
  spec.authors       = ["Ufuk Kayserilioglu", "Alan Wu", "Alexandre Terrasa", "Peter Zhu"]
  spec.email         = ["ruby@shopify.com"]

  spec.summary       = "Automatic Sorbet code style checking tool."
  spec.homepage      = "https://github.com/shopify/rubocop-sorbet"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shopify/rubocop-sorbet"
  spec.metadata["default_lint_roller_plugin"] = "RuboCop::Sorbet::Plugin"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("lint_roller")
  spec.add_runtime_dependency("rubocop", ">= 1.75.2")
end

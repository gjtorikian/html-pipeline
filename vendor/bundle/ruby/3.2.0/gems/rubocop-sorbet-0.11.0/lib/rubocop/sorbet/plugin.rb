# frozen_string_literal: true

require "rubocop"
require "lint_roller"
require "pathname"

module RuboCop
  module Sorbet
    # A plugin that integrates RuboCop Sorbet with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-sorbet",
          version: VERSION,
          homepage: "https://github.com/Shopify/rubocop-sorbet",
          description: "A collection of Rubocop rules for Sorbet.",
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        project_root = Pathname.new(__dir__).join("../../..")

        ConfigObsoletion.files << project_root.join("config", "obsoletion.yml")

        LintRoller::Rules.new(type: :path, config_format: :rubocop, value: project_root.join("config", "default.yml"))
      end
    end
  end
end

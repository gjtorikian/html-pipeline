# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module Minitest
    # A plugin that integrates RuboCop Minitest with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-minitest',
          version: Version::STRING,
          homepage: 'https://github.com/rubocop/rubocop-minitest',
          description: 'Automatic Minitest code style checking tool.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join('../../../config/default.yml')
        )
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

require_relative "plugins/base"

require_relative "plugins/actionpack"
require_relative "plugins/active_job"
require_relative "plugins/action_mailer_preview"
require_relative "plugins/action_mailer"
require_relative "plugins/active_model"
require_relative "plugins/active_record"
require_relative "plugins/active_support"
require_relative "plugins/graphql"
require_relative "plugins/minitest"
require_relative "plugins/namespaces"
require_relative "plugins/rails"
require_relative "plugins/rake"
require_relative "plugins/rspec"
require_relative "plugins/rubocop"
require_relative "plugins/ruby"
require_relative "plugins/sorbet"
require_relative "plugins/thor"

module Spoom
  module Deadcode
    DEFAULT_CUSTOM_PLUGINS_PATH = ".spoom/deadcode/plugins"

    DEFAULT_PLUGINS = Set.new([
      Spoom::Deadcode::Plugins::Namespaces,
      Spoom::Deadcode::Plugins::Ruby,
    ]).freeze #: Set[singleton(Plugins::Base)]

    PLUGINS_FOR_GEM = {
      "actionmailer" => Spoom::Deadcode::Plugins::ActionMailer,
      "actionpack" => Spoom::Deadcode::Plugins::ActionPack,
      "activejob" => Spoom::Deadcode::Plugins::ActiveJob,
      "activemodel" => Spoom::Deadcode::Plugins::ActiveModel,
      "activerecord" => Spoom::Deadcode::Plugins::ActiveRecord,
      "activesupport" => Spoom::Deadcode::Plugins::ActiveSupport,
      "graphql" => Spoom::Deadcode::Plugins::GraphQL,
      "minitest" => Spoom::Deadcode::Plugins::Minitest,
      "rails" => Spoom::Deadcode::Plugins::Rails,
      "rake" => Spoom::Deadcode::Plugins::Rake,
      "rspec" => Spoom::Deadcode::Plugins::RSpec,
      "rubocop" => Spoom::Deadcode::Plugins::Rubocop,
      "sorbet-runtime" => Spoom::Deadcode::Plugins::Sorbet,
      "sorbet-static" => Spoom::Deadcode::Plugins::Sorbet,
      "thor" => Spoom::Deadcode::Plugins::Thor,
    }.freeze #: Hash[String, singleton(Plugins::Base)]

    class << self
      #: (Context context) -> Set[singleton(Plugins::Base)]
      def plugins_from_gemfile_lock(context)
        # These plugins are always loaded
        plugin_classes = DEFAULT_PLUGINS.dup

        # These plugins depends on the gems used by the project
        context.gemfile_lock_specs.keys.each do |name|
          plugin_class = PLUGINS_FOR_GEM[name]
          plugin_classes << plugin_class if plugin_class
        end

        plugin_classes
      end

      #: (Context context) -> Array[singleton(Plugins::Base)]
      def load_custom_plugins(context)
        context.glob("#{DEFAULT_CUSTOM_PLUGINS_PATH}/*.rb").each do |path|
          require("#{context.absolute_path}/#{path}")
        end

        T.unsafe(ObjectSpace)
          .each_object(Class)
          .select do |klass|
            next unless T.unsafe(klass).name # skip anonymous classes, we only use them in tests
            next unless T.unsafe(klass) < Plugins::Base

            location = Object.const_source_location(T.unsafe(klass).to_s)&.first
            next unless location
            next unless location.start_with?("#{context.absolute_path}/#{DEFAULT_CUSTOM_PLUGINS_PATH}")

            true
          end
      end
    end
  end
end

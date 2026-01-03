# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      module TargetSorbetVersion
        class << self
          def included(target)
            target.extend(ClassMethods)
          end
        end

        module ClassMethods
          # Sets the version of the Sorbet static type checker required by this cop
          def minimum_target_sorbet_static_version(version)
            @minimum_target_sorbet_static_version = Gem::Version.new(version)
          end

          def supports_target_sorbet_static_version?(version)
            @minimum_target_sorbet_static_version <= Gem::Version.new(version)
          end
        end

        def sorbet_enabled?
          !target_sorbet_static_version_from_bundler_lock_file.nil?
        end

        def enabled_for_sorbet_static_version?
          sorbet_static_version = target_sorbet_static_version_from_bundler_lock_file
          return false unless sorbet_static_version

          self.class.supports_target_sorbet_static_version?(sorbet_static_version)
        end

        def target_sorbet_static_version_from_bundler_lock_file
          # Do memoization with the `defined?` pattern since sorbet-static version might be `nil`
          if defined?(@target_sorbet_static_version_from_bundler_lock_file)
            @target_sorbet_static_version_from_bundler_lock_file
          else
            @target_sorbet_static_version_from_bundler_lock_file = read_sorbet_static_version_from_bundler_lock_file
          end
        end

        def read_sorbet_static_version_from_bundler_lock_file
          require "bundler"
          ::Bundler.locked_gems.specs.find { |spec| spec.name == "sorbet-static" }&.version
        rescue LoadError, ::Bundler::GemfileNotFound
          nil
        end
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class GemVerify < AbstractGem
      private

      sig { override.void }
      def execute
        say("Checking for out-of-date RBIs...")
        say("")
        perform_sync_verification
      end

      sig { void }
      def perform_sync_verification
        diff = {}

        removed_rbis.each do |gem_name|
          next if @exclude.include?(gem_name)

          filename = existing_rbi(gem_name)
          diff[filename] = :removed
        end

        added_rbis.each do |gem_name|
          filename = expected_rbi(gem_name)
          diff[filename] = gem_rbi_exists?(gem_name) ? :changed : :added
        end

        report_diff_and_exit_if_out_of_date(diff, :gem)
      end
    end
  end
end

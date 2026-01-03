# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class CheckShims < CommandWithoutTracker
      extend T::Sig
      include SorbetHelper
      include RBIFilesHelper

      sig do
        params(
          gem_rbi_dir: String,
          dsl_rbi_dir: String,
          annotations_rbi_dir: String,
          shim_rbi_dir: String,
          todo_rbi_file: String,
          payload: T::Boolean,
          number_of_workers: T.nilable(Integer),
        ).void
      end
      def initialize(
        gem_rbi_dir:,
        dsl_rbi_dir:,
        annotations_rbi_dir:,
        shim_rbi_dir:,
        todo_rbi_file:,
        payload:,
        number_of_workers:
      )
        super()
        @gem_rbi_dir = gem_rbi_dir
        @dsl_rbi_dir = dsl_rbi_dir
        @annotations_rbi_dir = annotations_rbi_dir
        @shim_rbi_dir = shim_rbi_dir
        @todo_rbi_file = todo_rbi_file
        @payload = payload
        @number_of_workers = number_of_workers
      end

      private

      sig { override.void }
      def execute
        index = RBI::Index.new

        if (!Dir.exist?(@shim_rbi_dir) || Dir.empty?(@shim_rbi_dir)) && !File.exist?(@todo_rbi_file)
          say("No shim RBIs to check", :green)

          return
        end

        payload_path = T.let(nil, T.nilable(String))

        if @payload
          Dir.mktmpdir do |dir|
            payload_path = dir
            result = sorbet("--no-config --print=payload-sources:#{payload_path}")

            unless result.status
              raise Thor::Error, <<~ERROR
                "Sorbet failed to dump payload"
                #{result.err}
              ERROR
            end

            index_rbis(index, "payload", payload_path, number_of_workers: @number_of_workers)
          end
        end

        index_rbi(index, "todo", @todo_rbi_file)
        index_rbis(index, "shim", @shim_rbi_dir, number_of_workers: @number_of_workers)
        index_rbis(index, "gem", @gem_rbi_dir, number_of_workers: @number_of_workers)
        index_rbis(index, "dsl", @dsl_rbi_dir, number_of_workers: @number_of_workers)
        index_rbis(index, "annotation", @annotations_rbi_dir, number_of_workers: @number_of_workers)

        duplicates = duplicated_nodes_from_index(index, shim_rbi_dir: @shim_rbi_dir, todo_rbi_file: @todo_rbi_file)

        unless duplicates.empty?
          messages = []

          duplicates.each do |key, nodes|
            messages << set_color("\nDuplicated RBI for #{key}:", :red)

            nodes.each do |node|
              node_loc = node.loc

              next unless node_loc

              loc_string = location_to_payload_url(node_loc, path_prefix: payload_path)
              messages << set_color(" * #{loc_string}", :red)
            end
          end

          messages << set_color(
            "\nPlease remove the duplicated definitions from #{@shim_rbi_dir} and #{@todo_rbi_file}", :red
          )

          raise Thor::Error, messages.join("\n")
        end

        say("\nNo duplicates found in shim RBIs", :green)
      end
    end
  end
end

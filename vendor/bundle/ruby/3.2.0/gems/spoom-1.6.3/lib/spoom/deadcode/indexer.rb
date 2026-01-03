# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Indexer < Visitor
      #: String
      attr_reader :path

      #: Index
      attr_reader :index

      #: (String path, Index index, ?plugins: Array[Plugins::Base]) -> void
      def initialize(path, index, plugins: [])
        super()

        @path = path
        @index = index
        @plugins = plugins
      end

      # Visit

      # @override
      #: (Prism::CallNode node) -> void
      def visit_call_node(node)
        visit(node.receiver)

        send = Send.new(
          node: node,
          name: node.name.to_s,
          recv: node.receiver,
          args: node.arguments&.arguments || [],
          block: node.block,
          location: Location.from_prism(@path, node.location),
        )

        @plugins.each do |plugin|
          plugin.on_send(send)
        end

        visit(node.arguments)
        visit(send.block)
      end
    end
  end
end

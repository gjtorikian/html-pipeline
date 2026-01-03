# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    # An abstraction to simplify handling of Prism::CallNode nodes.
    class Send < T::Struct
      const :node, Prism::CallNode
      const :name, String
      const :recv, T.nilable(Prism::Node), default: nil
      const :args, T::Array[Prism::Node], default: []
      const :block, T.nilable(Prism::Node), default: nil
      const :location, Location

      #: [T] (Class[T] arg_type) { (T arg) -> void } -> void
      def each_arg(arg_type, &block)
        args.each do |arg|
          yield(T.unsafe(arg)) if arg.is_a?(arg_type)
        end
      end

      #: { (Prism::Node key, Prism::Node? value) -> void } -> void
      def each_arg_assoc(&block)
        args.each do |arg|
          next unless arg.is_a?(Prism::KeywordHashNode) || arg.is_a?(Prism::HashNode)

          arg.elements.each do |assoc|
            yield(assoc.key, assoc.value) if assoc.is_a?(Prism::AssocNode)
          end
        end
      end
    end
  end
end

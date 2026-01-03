# typed: strict
# frozen_string_literal: true

module RBI
  module Rewriters
    # Take a gem version and filter out all RBI that is not relevant to that version based on @version annotations
    # in comments. As an example:
    #
    # ~~~rb
    # tree = Parser.parse_string(<<~RBI)
    #   class Foo
    #     # @version > 0.3.0
    #     def bar
    #     end
    #
    #     # @version <= 0.3.0
    #     def bar(arg1)
    #     end
    #   end
    # RBI
    #
    # Rewriters::FilterVersions.filter(tree, Gem::Version.new("0.3.1"))
    #
    # assert_equal(<<~RBI, tree.string)
    #   class Foo
    #     # @version > 0.3.0
    #     def bar
    #     end
    #   end
    # RBI
    # ~~~
    #
    # Supported operators:
    # - equals `=`
    # - not equals `!=`
    # - greater than `>`
    # - greater than or equal to `>=`
    # - less than `<`
    # - less than or equal to `<=`
    # - pessimistic or twiddle-wakka`~>`
    #
    # And/or logic:
    # - "And" logic: put multiple versions on the same line
    #   - e.g. `@version > 0.3.0, <1.0.0` means version must be greater than 0.3.0 AND less than 1.0.0
    # - "Or" logic: put multiple versions on subsequent lines
    #   - e.g. the following means version must be less than 0.3.0 OR greater than 1.0.0
    #       ```
    #       # @version < 0.3.0
    #       # @version > 1.0.0
    #       ```
    # Prerelease versions:
    # - Prerelease versions are considered less than their non-prerelease counterparts
    #   - e.g. `0.4.0-prerelease` is less than `0.4.0`
    #
    # RBI with no versions:
    # - RBI with no version annotations are automatically counted towards ALL versions
    class FilterVersions < Visitor
      VERSION_PREFIX = "version "

      class << self
        #: (Tree tree, Gem::Version version) -> void
        def filter(tree, version)
          v = new(version)
          v.visit(tree)
        end
      end

      #: (Gem::Version version) -> void
      def initialize(version)
        super()
        @version = version
      end

      # @override
      #: (Node? node) -> void
      def visit(node)
        return unless node

        unless node.satisfies_version?(@version)
          node.detach
          return
        end

        visit_all(node.nodes.dup) if node.is_a?(Tree)
      end
    end
  end

  class Node
    #: (Gem::Version version) -> bool
    def satisfies_version?(version)
      return true unless is_a?(NodeWithComments)

      requirements = version_requirements
      requirements.empty? || requirements.any? { |req| req.satisfied_by?(version) }
    end
  end

  class NodeWithComments
    #: -> Array[Gem::Requirement]
    def version_requirements
      annotations.select do |annotation|
        annotation.start_with?(Rewriters::FilterVersions::VERSION_PREFIX)
      end.map do |annotation|
        versions = annotation.delete_prefix(Rewriters::FilterVersions::VERSION_PREFIX).split(/, */)
        Gem::Requirement.new(versions)
      end
    end
  end

  class Tree
    #: (Gem::Version version) -> void
    def filter_versions!(version)
      visitor = Rewriters::FilterVersions.new(version)
      visitor.visit(self)
    end
  end
end

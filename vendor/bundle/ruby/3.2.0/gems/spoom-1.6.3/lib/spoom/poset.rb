# typed: strict
# frozen_string_literal: true

module Spoom
  # A Poset is a set of elements with a partial order relation.
  #
  # The partial order relation is a binary relation that is reflexive, antisymmetric, and transitive.
  # It can be used to represent a hierarchy of classes or modules, the dependencies between gems, etc.
  class Poset
    extend T::Generic

    class Error < Spoom::Error; end

    E = type_member { { upper: Object } }

    #: -> void
    def initialize
      @elements = {} #: Hash[E, Element[E]]
    end

    # Get the POSet element for a given value
    #
    # Raises if the element is not found
    #: (E value) -> Element[E]
    def [](value)
      element = @elements[value]
      raise Error, "POSet::Element not found for #{value}" unless element

      element
    end

    # Add an element to the POSet
    #: (E value) -> Element[E]
    def add_element(value)
      element = @elements[value]
      return element if element

      @elements[value] = Element[E].new(value)
    end

    # Is the given value a element in the POSet?
    #: (E value) -> bool
    def element?(value)
      @elements.key?(value)
    end

    # Add a direct edge from one element to another
    #
    # Transitive edges (transitive closure) are automatically computed.
    # Adds the elements if they don't exist.
    # If the direct edge already exists, nothing is done.
    #: (E from, E to) -> void
    def add_direct_edge(from, to)
      from_element = add_element(from)
      to_element = add_element(to)

      # We already added this direct edge, which means we already computed the transitive closure
      return if from_element.parents.include?(to)

      # Add the direct edges
      from_element.dtos << to_element
      to_element.dfroms << from_element

      # Compute the transitive closure

      from_element.tos << to_element
      from_element.froms.each do |child_element|
        child_element.tos << to_element
        to_element.froms << child_element

        to_element.tos.each do |parent_element|
          parent_element.froms << child_element
          child_element.tos << parent_element
        end
      end

      to_element.froms << from_element
      to_element.tos.each do |parent_element|
        parent_element.froms << from_element
        from_element.tos << parent_element

        from_element.froms.each do |child_element|
          child_element.tos << parent_element
          parent_element.froms << child_element
        end
      end
    end

    # Is there an edge (direct or indirect) from `from` to `to`?
    #: (E from, E to) -> bool
    def edge?(from, to)
      from_element = @elements[from]
      return false unless from_element

      from_element.ancestors.include?(to)
    end

    # Is there a direct edge from `from` to `to`?
    #: (E from, E to) -> bool
    def direct_edge?(from, to)
      self[from].parents.include?(to)
    end

    # Show the POSet as a DOT graph using xdot (used for debugging)
    #: (?direct: bool, ?transitive: bool) -> void
    def show_dot(direct: true, transitive: true)
      Open3.popen3("xdot -") do |stdin, _stdout, _stderr, _thread|
        stdin.write(to_dot(direct: direct, transitive: transitive))
        stdin.close
      end
    end

    # Return the POSet as a DOT graph
    #: (?direct: bool, ?transitive: bool) -> String
    def to_dot(direct: true, transitive: true)
      dot = +"digraph {\n"
      dot << "  rankdir=BT;\n"
      @elements.each do |value, element|
        dot << "  \"#{value}\";\n"
        if direct
          element.parents.each do |to|
            dot << "  \"#{value}\" -> \"#{to}\";\n"
          end
        end
        if transitive # rubocop:disable Style/Next
          element.ancestors.each do |ancestor|
            dot << "  \"#{value}\" -> \"#{ancestor}\" [style=dotted];\n"
          end
        end
      end
      dot << "}\n"
    end

    # An element in a POSet
    class Element
      extend T::Generic
      include Comparable

      E = type_member { { upper: Object } }

      # The value held by this element
      #: E
      attr_reader :value

      # Edges (direct and indirect) from this element to other elements in the same POSet
      #: Set[Element[E]]
      attr_reader :dtos, :tos, :dfroms, :froms

      #: (E value) -> void
      def initialize(value)
        @value = value
        @dtos = Set.new #: Set[Element[E]]
        @tos = Set.new #: Set[Element[E]]
        @dfroms = Set.new #: Set[Element[E]]
        @froms = Set.new #: Set[Element[E]]
      end

      #: (untyped other) -> Integer?
      def <=>(other)
        return unless other.is_a?(Element)
        return 0 if self == other

        if tos.include?(other)
          -1
        elsif froms.include?(other)
          1
        end
      end

      # Direct parents of this element
      #: -> Array[E]
      def parents
        @dtos.map(&:value)
      end

      # Direct and indirect ancestors of this element
      #: -> Array[E]
      def ancestors
        @tos.map(&:value)
      end

      # Direct children of this element
      #: -> Array[E]
      def children
        @dfroms.map(&:value)
      end

      # Direct and indirect descendants of this element
      #: -> Array[E]
      def descendants
        @froms.map(&:value)
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

module YARDSorbet
  module Handlers
    # Applies an `@abstract` tag to `abstract!`/`interface!` modules (if not alerady present).
    class AbstractDSLHandler < YARD::Handlers::Ruby::Base
      extend T::Sig

      handles method_call(:abstract!), method_call(:interface!)
      namespace_only

      # The text accompanying the `@abstract` tag.
      # @see https://github.com/lsegal/yard/blob/main/templates/default/docstring/html/abstract.erb
      #   The `@abstract` tag template
      TAG_TEXT = 'Subclasses must implement the `abstract` methods below.'
      # Extra text for class namespaces
      CLASS_TAG_TEXT = T.let("It cannot be directly instantiated. #{TAG_TEXT}".freeze, String)

      sig { void }
      def process
        return if namespace.has_tag?(:abstract)

        text = namespace.is_a?(YARD::CodeObjects::ClassObject) ? CLASS_TAG_TEXT : TAG_TEXT
        tag = YARD::Tags::Tag.new(:abstract, text)
        namespace.add_tag(tag)
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

module YARDSorbet
  # Helper methods for working with `YARD` tags
  module TagUtils
    extend T::Sig

    # The `void` return type, as a constant to reduce array allocations
    VOID_RETURN_TYPE = T.let(['void'].freeze, [String])

    # @return the tag with the matching `tag_name` and `name`, or `nil`
    sig do
      params(docstring: YARD::Docstring, tag_name: String, name: T.nilable(String)).returns(T.nilable(YARD::Tags::Tag))
    end
    def self.find_tag(docstring, tag_name, name) = docstring.tags.find { _1.tag_name == tag_name && _1.name == name }

    # Create or update a `YARD` tag with type information
    sig do
      params(
        docstring: YARD::Docstring,
        tag_name: String,
        types: T.nilable(T::Array[String]),
        name: T.nilable(String),
        text: String
      ).void
    end
    def self.upsert_tag(docstring, tag_name, types = nil, name = nil, text = '')
      tag = find_tag(docstring, tag_name, name)
      if tag
        return unless types

        # Updating a tag in place doesn't seem to work, so we'll delete it, add the types, and re-add it
        docstring.delete_tag_if { _1 == tag }
        # overwrite any existing type annotation (sigs should win)
        tag.types = types
        tag.text = text unless text.empty?
      else
        tag = YARD::Tags::Tag.new(tag_name, text, types, name)
      end
      docstring.add_tag(tag)
    end
  end
end

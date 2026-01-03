# typed: strong
# frozen_string_literal: true

module YARDSorbet
  # Used to store the details of a `T::Struct` `prop` definition
  class TStructProp < T::Struct
    const :default, T.nilable(String)
    const :doc, String
    const :prop_name, String
    const :source, String
    const :types, T::Array[String]
  end
end

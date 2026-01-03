# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Compilers
      # DSL compilers are either built-in to Tapioca and live under the
      # `Tapioca::Dsl::Compilers` namespace (i.e. this namespace), and
      # can be referred to by just using the class name, or they live in
      # a different namespace and can only be referred to using their fully
      # qualified name. This constant encapsulates that dual lookup when
      # a compiler needs to be resolved by name.
      NAMESPACES = T.let(
        [
          "#{name}::", # compilers in this namespace
          "::", # compilers that need to be fully namespaced
        ],
        T::Array[String],
      )
    end
  end
end

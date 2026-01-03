# typed: strict
# frozen_string_literal: true

module Tapioca
  class GemInfo < T::Struct
    const :name, String
    const :version, ::Gem::Version

    class << self
      extend(T::Sig)

      sig { params(spec: Bundler::LazySpecification).returns(GemInfo) }
      def from_spec(spec)
        new(name: spec.name, version: spec.version)
      end
    end
  end
end

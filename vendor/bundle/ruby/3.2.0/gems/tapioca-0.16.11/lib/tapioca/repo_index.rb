# typed: strict
# frozen_string_literal: true

module Tapioca
  class RepoIndex
    extend T::Sig
    extend T::Generic

    class << self
      extend T::Sig

      sig { params(json: String).returns(RepoIndex) }
      def from_json(json)
        RepoIndex.from_hash(JSON.parse(json))
      end

      sig { params(hash: T::Hash[String, T::Hash[T.untyped, T.untyped]]).returns(RepoIndex) }
      def from_hash(hash)
        hash.each_with_object(RepoIndex.new) do |(name, _), index|
          index << name
        end
      end
    end

    sig { void }
    def initialize
      @entries = T.let(Set.new, T::Set[String])
    end

    sig { params(gem_name: String).void }
    def <<(gem_name)
      @entries.add(gem_name)
    end

    sig { returns(T::Enumerable[String]) }
    def gems
      @entries.sort
    end

    sig { params(gem_name: String).returns(T::Boolean) }
    def has_gem?(gem_name)
      @entries.include?(gem_name)
    end
  end
end

# frozen_string_literal: true

# This is true for Ruby 3.2+, so once support for 3.1 is dropped, we can remove this.
# Until then, some installations may have a recent enough version of RubyGems, but it is not guaranteed.
return if Gem::Version.new(Gem::VERSION) >= Gem::Version.new("3.5.6")

module RuboCop
  module Shopify
    # Backport rubygems/rubygems#5275, so we can compare `Gem::Version`s directly against `String`s.
    #
    #     Gem::Version.new("1.2.3") > "1.2"
    #
    # Without this, to support Ruby < 3.2, we would have to create a new `Gem::Version` instance ourselves.
    #
    #     Gem::Version.new("1.2.3") > Gem::Version.new("1.2")
    #
    # This would get very verbose in our RuboCop config files.
    module GemVersionStringComparableBackport
      def <=>(other)
        return self <=> self.class.new(other) if (String === other) && self.class.correct?(other)

        super
      end

      Gem::Version.prepend(self)
    end
  end
end

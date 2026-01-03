# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class CommandWithoutTracker < Command
      extend T::Helpers

      abstract!

      sig { void }
      def initialize
        Tapioca::Runtime::Trackers.disable_all!
        super
      end
    end
  end
end

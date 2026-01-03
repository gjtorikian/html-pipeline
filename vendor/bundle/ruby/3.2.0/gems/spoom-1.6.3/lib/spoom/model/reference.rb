# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    # A reference to something that looks like a constant or a method
    #
    # Constants could be classes, modules, or actual constants.
    # Methods could be accessors, instance or class methods, aliases, etc.
    class Reference < T::Struct
      class Kind < T::Enum
        enums do
          Constant = new("constant")
          Method = new("method")
        end
      end

      class << self
        #: (String name, Spoom::Location location) -> Reference
        def constant(name, location)
          new(name: name, kind: Kind::Constant, location: location)
        end

        #: (String name, Spoom::Location location) -> Reference
        def method(name, location)
          new(name: name, kind: Kind::Method, location: location)
        end
      end

      const :kind, Kind
      const :name, String
      const :location, Spoom::Location

      #: -> bool
      def constant?
        kind == Kind::Constant
      end

      #: -> bool
      def method?
        kind == Kind::Method
      end
    end
  end
end

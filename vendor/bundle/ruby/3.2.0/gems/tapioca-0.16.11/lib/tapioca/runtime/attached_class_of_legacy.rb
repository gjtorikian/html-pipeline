# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    # This module should only be included when running versions of Ruby
    # older than 3.2. Because the Class#attached_object method is not
    # available, it implements finding the attached class of a singleton
    # class by iterating through ObjectSpace.
    module AttachedClassOf
      extend T::Sig
      extend T::Helpers

      requires_ancestor { Tapioca::Runtime::Reflection }

      sig { params(singleton_class: Class).returns(T.nilable(Module)) }
      def attached_class_of(singleton_class)
        # https://stackoverflow.com/a/36622320/98634
        result = ObjectSpace.each_object(singleton_class).find do |klass|
          singleton_class_of(T.cast(klass, Module)) == singleton_class
        end

        T.cast(result, T.nilable(Module))
      end
    end
  end
end

# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Check that code does not call `mixes_in_class_methods` from Sorbet `T::Helpers`.
      #
      # Good:
      #
      # ```
      # module M
      #   extend ActiveSupport::Concern
      #
      #   class_methods do
      #     ...
      #   end
      # end
      # ```
      #
      # Bad:
      #
      # ```
      # module M
      #   extend T::Helpers
      #
      #   module ClassMethods
      #     ...
      #   end
      #
      #   mixes_in_class_methods(ClassMethods)
      # end
      # ```
      class ForbidMixesInClassMethods < ::RuboCop::Cop::Base
        MSG = "Do not use `mixes_in_class_methods`, use `extend ActiveSupport::Concern` instead."
        RESTRICT_ON_SEND = [:mixes_in_class_methods].freeze

        # @!method mixes_in_class_methods?(node)
        def_node_matcher(:mixes_in_class_methods?, <<~PATTERN)
          (send {self | nil? | (const (const {cbase | nil?} :T) :Helpers)} :mixes_in_class_methods ...)
        PATTERN

        def on_send(node)
          add_offense(node) if mixes_in_class_methods?(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end

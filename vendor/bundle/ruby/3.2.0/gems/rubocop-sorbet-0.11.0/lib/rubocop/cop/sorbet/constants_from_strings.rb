# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows the calls that are used to get constants fom Strings
      # such as +constantize+, +const_get+, and +constants+.
      #
      # The goal of this cop is to make the code easier to statically analyze,
      # more IDE-friendly, and more predictable. It leads to code that clearly
      # expresses which values the constant can have.
      #
      # @example
      #
      #   # bad
      #   class_name.constantize
      #
      #   # bad
      #   constants.detect { |c| c.name == "User" }
      #
      #   # bad
      #   const_get(class_name)
      #
      #   # good
      #   case class_name
      #   when "User"
      #     User
      #   else
      #     raise ArgumentError
      #   end
      #
      #   # good
      #   { "User" => User }.fetch(class_name)
      class ConstantsFromStrings < ::RuboCop::Cop::Base
        MSG = "Don't use `%<method_name>s`, it makes the code harder to understand, less editor-friendly, " \
          "and impossible to analyze. Replace `%<method_name>s` with a case/when or a hash."

        RESTRICT_ON_SEND = [
          :constantize,
          :constants,
          :const_get,
          :safe_constantize,
        ].freeze

        def on_send(node)
          add_offense(node.selector, message: format(MSG, method_name: node.method_name))
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end

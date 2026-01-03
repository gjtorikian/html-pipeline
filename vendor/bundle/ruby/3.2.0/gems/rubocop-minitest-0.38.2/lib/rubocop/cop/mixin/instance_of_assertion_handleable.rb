# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # Common functionality for `Minitest/AssertInstanceOf` and `Minitest/RefuteInstanceOf` cops.
      # @api private
      module InstanceOfAssertionHandleable
        include ArgumentRangeHelper

        MSG = 'Prefer using `%<prefer>s`.'

        private

        def investigate(node, assertion_type)
          return unless (first_capture, second_capture, message = instance_of_assertion?(node))

          required_arguments = build_required_arguments(node, assertion_type, first_capture, second_capture)
          full_arguments = [required_arguments, message.first&.source].compact.join(', ')
          prefer = "#{assertion_type}_instance_of(#{full_arguments})"

          add_offense(node, message: format(MSG, prefer: prefer)) do |corrector|
            range = replacement_range(node, assertion_type)

            corrector.replace(node.loc.selector, "#{assertion_type}_instance_of")
            corrector.replace(range, required_arguments)
          end
        end

        def build_required_arguments(node, method_name, first_capture, second_capture)
          if node.method?(method_name)
            [second_capture, first_capture]
          else
            [first_capture, second_capture]
          end.map(&:source).join(', ')
        end

        def replacement_range(node, method_name)
          if node.method?(method_name)
            node.first_argument
          else
            first_and_second_arguments_range(node)
          end
        end
      end
    end
  end
end

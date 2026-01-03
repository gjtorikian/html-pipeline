# frozen_string_literal: true

module RuboCop
  module Cop
    # Provide a method to define offense rule for Minitest cops.
    module MinitestCopRule
      #
      # Define offense rule for Minitest cops.
      #
      # @example
      #   define_rule :assert, target_method: :match
      #   define_rule :refute, target_method: :match
      #   define_rule :assert, target_method: :include?, preferred_method: :assert_includes
      #   define_rule :assert, target_method: :instance_of?, inverse: true
      #
      # @example Multiple target methods
      #   # `preferred_method` is required
      #   define_rule :assert, target_method: %i[match match? =~],
      #               preferred_method: :assert_match, inverse: 'regexp_type?'
      #
      # @param assertion_method [Symbol] Assertion method like `assert` or `refute`.
      # @param target_method [Symbol, Array<Symbol>] Method name(s) offensed by assertion method arguments.
      # @param preferred_method [Symbol] Is required if passing multiple target methods. Custom method name replaced by
      #                                  autocorrection. The preferred method name that connects
      #                                  `assertion_method` and `target_method` with `_` is
      #                                  the default name.
      # @param inverse [Boolean, String] An optional param. Order of arguments replaced by autocorrection.
      #                                  If string is passed, it becomes a predicate method for the first argument node.
      # @api private
      #
      def define_rule(assertion_method, target_method:, preferred_method: nil, inverse: false)
        target_methods = Array(target_method)
        if target_methods.size > 1 && preferred_method.nil?
          raise ArgumentError, '`:preferred_method` keyword argument must be used if using more than one target method.'
        end

        preferred_method = "#{assertion_method}_#{target_methods.first.to_s.delete('?')}" if preferred_method.nil?

        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          include ArgumentRangeHelper
          extend AutoCorrector

          MSG = 'Prefer using `#{preferred_method}(%<new_arguments>s)`.'
          RESTRICT_ON_SEND = %i[#{assertion_method}].freeze

          def on_send(node)
            return unless node.method?(:#{assertion_method})
            return unless node.arguments.first&.call_type?
            return if node.arguments.first.arguments.empty? ||
                      #{target_methods}.none? { |target_method| node.arguments.first.method?(target_method) }

            add_offense(node, message: offense_message(node.arguments)) do |corrector|
              autocorrect(corrector, node, node.arguments)
            end
          end

          def autocorrect(corrector, node, arguments)
            corrector.replace(node.loc.selector, '#{preferred_method}')

            new_arguments = new_arguments(arguments).join(', ')

            corrector.replace(node.first_argument, new_arguments)
          end

          private

          def offense_message(arguments)
            message_argument = arguments.last if arguments.first != arguments.last

            new_arguments = [
              new_arguments(arguments),
              message_argument&.source
            ].flatten.compact.join(', ')

            format(
              MSG,
              new_arguments: new_arguments
            )
          end

          def new_arguments(arguments)
            receiver = correct_receiver(arguments.first.receiver)
            method_argument = arguments.first.arguments.first

            new_arguments = [receiver, method_argument&.source].compact
            inverse_condition = if %w[true false].include?('#{inverse}')
              #{inverse}
            else
              method_argument.#{inverse}
            end
            new_arguments.reverse! if inverse_condition
            new_arguments
          end

          def correct_receiver(receiver)
            receiver ? receiver.source : 'self'
          end
        RUBY
      end
    end
  end
end

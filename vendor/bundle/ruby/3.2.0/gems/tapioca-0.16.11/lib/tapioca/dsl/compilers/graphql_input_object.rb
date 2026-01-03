# typed: strict
# frozen_string_literal: true

return unless defined?(GraphQL::Schema::InputObject)
return unless Gem::Requirement.new(">= 1.13").satisfied_by?(Gem::Version.new(GraphQL::VERSION))

require "tapioca/dsl/helpers/graphql_type_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::GraphqlInputObject` generates RBI files for subclasses of
      # [`GraphQL::Schema::InputObject`](https://graphql-ruby.org/api-doc/2.0.11/GraphQL/Schema/InputObject).
      #
      # For example, with the following `GraphQL::Schema::InputObject` subclass:
      #
      # ~~~rb
      # class CreateCommentInput < GraphQL::Schema::InputObject
      #   argument :body, String, required: true
      #   argument :post_id, ID, required: true
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `notify_user_job.rbi` with the following content:
      #
      # ~~~rbi
      # # create_comment.rbi
      # # typed: true
      # class CreateCommentInput
      #   sig { returns(String) }
      #   def body; end
      #
      #   sig { returns(String) }
      #   def post_id; end
      # end
      # ~~~
      class GraphqlInputObject < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(GraphQL::Schema::InputObject) } }

        sig { override.void }
        def decorate
          # Skip methods explicitly defined in code
          arguments = constant.all_argument_definitions.select do |argument|
            method_defined_by_graphql?(argument.keyword.to_s)
          end

          return if arguments.empty?

          root.create_path(constant) do |input_object|
            arguments.each do |argument|
              name = argument.keyword.to_s
              input_object.create_method(
                name,
                return_type: Helpers::GraphqlTypeHelper.type_for_argument(argument, constant),
              )
            end
          end
        end

        private

        sig { returns(T.nilable(String)) }
        def graphql_input_object_argument_source_file
          @graphql_input_object_argument_source_file ||= T.let(
            GraphQL::Schema::InputObject.method(:argument).source_location&.first,
            T.nilable(String),
          )
        end

        sig { params(method_name: String).returns(T::Boolean) }
        def method_defined_by_graphql?(method_name)
          method_file = constant.instance_method(method_name).source_location&.first
          !!(method_file && graphql_input_object_argument_source_file == method_file)
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| GraphQL::Schema::InputObject > c }
          end
        end
      end
    end
  end
end

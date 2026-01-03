# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActionText` decorates RBI files for subclasses of
      # `ActiveRecord::Base` that declare [has_rich_text](https://edgeguides.rubyonrails.org/action_text_overview.html#creating-rich-text-content)
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      #  has_rich_text :body
      #  has_rich_text :title, encrypted: true
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # typed: strong
      #
      # class Post
      #  sig { returns(ActionText::RichText) }
      #  def body; end
      #
      #  sig { params(value: T.nilable(T.any(ActionText::RichText, String))).returns(T.untyped) }
      #  def body=(value); end
      #
      #  sig { returns(T::Boolean) }
      #  def body?; end
      #
      #  sig { returns(ActionText::EncryptedRichText) }
      #  def title; end
      #
      #  sig { params(value: T.nilable(T.any(ActionText::EncryptedRichText, String))).returns(T.untyped) }
      #  def title=(value); end
      #
      #  sig { returns(T::Boolean) }
      #  def title?; end
      # end
      # ~~~
      class ActionText < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        sig { override.void }
        def decorate
          root.create_path(constant) do |scope|
            self.class.action_text_associations(constant).each do |name|
              reflection = constant.reflections.fetch(name)
              type = reflection.options.fetch(:class_name)
              name = reflection.name.to_s.sub("rich_text_", "")
              scope.create_method(
                name,
                return_type: type,
              )
              scope.create_method(
                "#{name}?",
                return_type: "T::Boolean",
              )
              scope.create_method(
                "#{name}=",
                parameters: [create_param("value", type: "T.nilable(T.any(#{type}, String))")],
                return_type: "T.untyped",
              )
            end
          end
        end

        class << self
          extend T::Sig

          sig { params(constant: T.class_of(::ActiveRecord::Base)).returns(T::Array[String]) }
          def action_text_associations(constant)
            # Implementation copied from https://github.com/rails/rails/blob/31052d0e518b9da103eea2f79d250242ed1e3705/actiontext/lib/action_text/attribute.rb#L66
            constant.reflect_on_all_associations(:has_one)
              .map(&:name).map(&:to_s)
              .select { |n| n.start_with?("rich_text_") }
          end

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActiveRecord::Base)
              .reject(&:abstract_class?)
              .select { |c| action_text_associations(c).any? }
          end
        end
      end
    end
  end
end

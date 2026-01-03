# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallow using `T::Struct` and `T::Props`.
      #
      # @example
      #
      #   # bad
      #   class MyStruct < T::Struct
      #     const :foo, String
      #     prop :bar, Integer, default: 0
      #
      #     def some_method; end
      #   end
      #
      #   # good
      #   class MyStruct
      #     extend T::Sig
      #
      #     sig { returns(String) }
      #     attr_reader :foo
      #
      #     sig { returns(Integer) }
      #     attr_accessor :bar
      #
      #     sig { params(foo: String, bar: Integer) }
      #     def initialize(foo:, bar: 0)
      #       @foo = foo
      #       @bar = bar
      #     end
      #
      #     def some_method; end
      #   end
      class ForbidTStruct < RuboCop::Cop::Base
        include Alignment
        include RangeHelp
        include CommentsHelp
        extend AutoCorrector

        RESTRICT_ON_SEND = [:include, :prepend, :extend].freeze

        MSG_STRUCT = "Using `T::Struct` or its variants is deprecated in this codebase."
        MSG_PROPS = "Using `T::Props` or its variants is deprecated in this codebase."

        # This class walks down the class body of a T::Struct and collects all the properties that will need to be
        # translated into `attr_reader` and `attr_accessor` methods.
        class TStructWalker
          include AST::Traversal
          extend AST::NodePattern::Macros

          attr_reader :props, :has_extend_t_sig

          def initialize
            @props = []
            @has_extend_t_sig = false
          end

          # @!method extend_t_sig?(node)
          def_node_matcher :extend_t_sig?, <<~PATTERN
            (send _ :extend (const (const {nil? | cbase} :T) :Sig))
          PATTERN

          # @!method t_struct_prop?(node)
          def_node_matcher(:t_struct_prop?, <<~PATTERN)
            (send nil? {:const :prop} ...)
          PATTERN

          def on_send(node)
            if extend_t_sig?(node)
              # So we know we won't need to generate again a `extend T::Sig` line in the new class body
              @has_extend_t_sig = true
              return
            end

            return unless t_struct_prop?(node)

            kind = node.method?(:const) ? :attr_reader : :attr_accessor
            name = node.first_argument.source.delete_prefix(":")
            type = node.arguments[1].source
            default = nil
            factory = nil

            node.arguments[2..-1].each do |arg|
              next unless arg.hash_type?

              arg.each_pair do |key, value|
                case key.source
                when "default"
                  default = value.source
                when "factory"
                  factory = value.source
                end
              end
            end

            @props << Property.new(node, kind, name, type, default: default, factory: factory)
          end
        end

        class Property
          attr_reader :node, :kind, :name, :default, :factory

          def initialize(node, kind, name, type, default:, factory:)
            @node = node
            @kind = kind
            @name = name
            @type = type
            @default = default
            @factory = factory

            # A T::Struct should have both a default and a factory, if we find one let's raise an error
            raise if @default && @factory
          end

          def attr_sig
            "sig { returns(#{type}) }"
          end

          def attr_accessor
            "#{kind} :#{name}"
          end

          def initialize_sig_param
            "#{name}: #{type}"
          end

          def initialize_param
            rb = String.new
            rb << "#{name}:"
            if default
              rb << " #{default}"
            elsif factory
              rb << " #{factory}"
            elsif nilable?
              rb << " nil"
            end
            rb
          end

          def initialize_assign
            rb = String.new
            rb << "@#{name} = #{name}"
            rb << ".call" if factory
            rb
          end

          def nilable?
            type.start_with?("T.nilable(")
          end

          def type
            copy = @type.gsub(/[[:space:]]+/, "").strip # Remove newlines and spaces
            copy.gsub(",", ", ") # Add a space after each comma
          end
        end

        # @!method t_struct?(node)
        def_node_matcher(:t_struct?, <<~PATTERN)
          (const (const {nil? cbase} :T) {:Struct :ImmutableStruct :InexactStruct})
        PATTERN

        # @!method t_props?(node)
        def_node_matcher(:t_props?, "(send nil? {:include :prepend :extend} `(const (const {nil? cbase} :T) :Props))")

        def on_class(node)
          return unless t_struct?(node.parent_class)

          add_offense(node, message: MSG_STRUCT) do |corrector|
            walker = TStructWalker.new
            walker.walk(node.body)

            range = range_between(node.identifier.source_range.end_pos, node.parent_class.source_range.end_pos)
            corrector.remove(range)
            next if node.single_line?

            unless walker.has_extend_t_sig
              indent = offset(node)
              corrector.insert_after(node.identifier, "\n#{indent}  extend T::Sig\n")
            end

            first_prop = walker.props.first
            walker.props.each do |prop|
              node = prop.node
              indent = offset(node)
              line_range = range_by_whole_lines(prop.node.source_range)
              new_line = prop != first_prop && !previous_line_blank?(node)
              trailing_comments = processed_source.each_comment_in_lines(line_range.line..line_range.line)

              corrector.replace(
                line_range,
                "#{new_line ? "\n" : ""}" \
                  "#{trailing_comments.map { |comment| "#{indent}#{comment.text}\n" }.join}" \
                  "#{indent}#{prop.attr_sig}\n#{indent}#{prop.attr_accessor}",
              )
            end

            last_prop = walker.props.last
            if last_prop
              indent = offset(last_prop.node)
              line_range = range_by_whole_lines(last_prop.node.source_range, include_final_newline: true)
              corrector.insert_after(line_range, initialize_method(indent, walker.props))
            end
          end
        end

        def on_send(node)
          return unless t_props?(node)

          add_offense(node, message: MSG_PROPS)
        end

        private

        def initialize_method(indent, props)
          # We sort optional keyword arguments after required ones
          sorted_props = props.sort_by { |prop| prop.default || prop.factory || prop.nilable? ? 1 : 0 }

          string = +"\n"

          line = "#{indent}sig { params(#{sorted_props.map(&:initialize_sig_param).join(", ")}).void }\n"
          if line.length <= max_line_length
            string << line
          else
            string << "#{indent}sig do\n"
            string << "#{indent}  params(\n"
            sorted_props.each do |prop|
              string << "#{indent}    #{prop.initialize_sig_param}"
              string << "," if prop != sorted_props.last
              string << "\n"
            end
            string << "#{indent}  ).void\n"
            string << "#{indent}end\n"
          end

          line = "#{indent}def initialize(#{sorted_props.map(&:initialize_param).join(", ")})\n"
          if line.length <= max_line_length
            string << line
          else
            string << "#{indent}def initialize(\n"
            sorted_props.each do |prop|
              string << "#{indent}  #{prop.initialize_param}"
              string << "," if prop != sorted_props.last
              string << "\n"
            end
            string << "#{indent})\n"
          end

          props.each do |prop|
            string << "#{indent}  #{prop.initialize_assign}\n"
          end
          string << "#{indent}end\n"
        end

        def previous_line_blank?(node)
          processed_source.buffer.source_line(node.source_range.line - 1).blank?
        end
      end
    end
  end
end

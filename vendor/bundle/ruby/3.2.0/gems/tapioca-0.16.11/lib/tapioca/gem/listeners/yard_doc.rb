# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class YardDoc < Base
        extend T::Sig

        IGNORED_COMMENTS = T.let(
          [
            ":doc:",
            ":nodoc:",
            "typed:",
            "frozen_string_literal:",
            "encoding:",
            "warn_indent:",
            "shareable_constant_value:",
            "rubocop:",
          ],
          T::Array[String],
        )

        IGNORED_SIG_TAGS = T.let(["param", "return"], T::Array[String])

        sig { params(pipeline: Pipeline).void }
        def initialize(pipeline)
          YARD::Registry.clear
          super(pipeline)
          pipeline.gem.parse_yard_docs
        end

        private

        sig { override.params(event: ConstNodeAdded).void }
        def on_const(event)
          event.node.comments = documentation_comments(event.symbol)
        end

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          event.node.comments = documentation_comments(event.symbol)
        end

        sig { override.params(event: MethodNodeAdded).void }
        def on_method(event)
          separator = event.constant.singleton_class? ? "." : "#"
          event.node.comments = documentation_comments(
            "#{event.symbol}#{separator}#{event.node.name}",
            sigs: event.node.sigs,
          )
        end

        sig { params(name: String, sigs: T::Array[RBI::Sig]).returns(T::Array[RBI::Comment]) }
        def documentation_comments(name, sigs: [])
          yard_docs = YARD::Registry.at(name)
          return [] unless yard_docs

          docstring = yard_docs.docstring
          return [] if /(copyright|license)/i.match?(docstring)

          comments = docstring.lines
            .reject { |line| IGNORED_COMMENTS.any? { |comment| line.include?(comment) } }
            .map! { |line| RBI::Comment.new(line) }

          tags = yard_docs.tags
          tags.reject! { |tag| IGNORED_SIG_TAGS.include?(tag.tag_name) } unless sigs.empty?

          comments << RBI::Comment.new("") if comments.any? && tags.any?

          tags.sort_by(&:tag_name).each do |tag|
            line = +"@#{tag.tag_name}"

            tag_name = tag.name
            line << " #{tag_name}" if tag_name

            tag_types = tag.types
            line << " [#{tag_types.join(", ")}]" if tag_types&.any?

            tag_text = tag.text
            if tag_text && !tag_text.empty?
              text_lines = tag_text.lines

              # Example are a special case because we want the text to start on the next line
              line << " #{text_lines.shift&.strip}" unless tag.tag_name == "example"

              text_lines.each do |text_line|
                line << "\n  #{text_line.strip}"
              end
            end

            comments << RBI::Comment.new(line)
          end

          comments
        end

        sig { override.params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end

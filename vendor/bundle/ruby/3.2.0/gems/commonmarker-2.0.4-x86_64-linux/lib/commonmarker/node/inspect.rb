# frozen_string_literal: true

require "pp"

module Commonmarker
  class Node
    module Inspect
      PP_INDENT_SIZE = 2

      def inspect
        PP.pp(self, +"", Float::INFINITY)
      end

      # @param printer [PrettyPrint] pp
      def pretty_print(printer)
        printer.group(PP_INDENT_SIZE, "#<#{self.class}(#{type}):", ">") do
          printer.breakable

          attrs = [
            :source_position,
            :string_content,
            :url,
            :title,
            :header_level,
            :list_type,
            :list_start,
            :list_tight,
            :fence_info,
          ].filter_map do |name|
            [name, __send__(name)]
          rescue StandardError
            nil
          end.compact

          printer.seplist(attrs) do |name, value|
            printer.text("#{name}=")
            printer.pp(value)
          end

          if first_child
            printer.breakable
            printer.group(PP_INDENT_SIZE) do
              children = []
              node = first_child
              while node
                children << node
                node = node.next_sibling
              end
              printer.text("children=")
              printer.pp(children)
            end
          end
        end
      end
    end
  end
end

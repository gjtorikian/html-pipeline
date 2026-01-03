# typed: true
# frozen_string_literal: true

# Copied from https://github.com/rails/rails/blob/main/actionview/lib/action_view/template/handlers/erb/erubi.rb.
#
# Copyright (c) David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module Spoom
  module Deadcode
    # Custom engine to handle ERB templates as used by Rails
    class ERB < ::Erubi::Engine
      #: (untyped input, ?untyped properties) -> void
      def initialize(input, properties = {})
        @newline_pending = 0

        properties = Hash[properties]
        properties[:bufvar]     ||= "@output_buffer"
        properties[:preamble]   ||= ""
        properties[:postamble]  ||= "#{properties[:bufvar]}.to_s"
        properties[:escapefunc] = ""

        super
      end

      private

      # @override
      #: (untyped text) -> void
      def add_text(text)
        return if text.empty?

        if text == "\n"
          @newline_pending += 1
        else
          src << bufvar << ".safe_append='"
          src << "\n" * @newline_pending if @newline_pending > 0
          src << text.gsub(/['\\]/, '\\\\\&')
          src << "'.freeze;"

          @newline_pending = 0
        end
      end

      BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/

      # @override
      #: (untyped indicator, untyped code) -> void
      def add_expression(indicator, code)
        flush_newline_if_pending(src)

        src << bufvar << if (indicator == "==") || @escape
          ".safe_expr_append="
        else
          ".append="
        end

        if BLOCK_EXPR.match?(code)
          src << " " << code
        else
          src << "(" << code << ");"
        end
      end

      # @override
      #: (untyped code) -> void
      def add_code(code)
        flush_newline_if_pending(src)
        super
      end

      # @override
      #: (untyped _) -> void
      def add_postamble(_)
        flush_newline_if_pending(src)
        super
      end

      #: (untyped src) -> void
      def flush_newline_if_pending(src)
        if @newline_pending > 0
          src << bufvar << ".safe_append='#{"\n" * @newline_pending}'.freeze;"
          @newline_pending = 0
        end
      end
    end
  end
end

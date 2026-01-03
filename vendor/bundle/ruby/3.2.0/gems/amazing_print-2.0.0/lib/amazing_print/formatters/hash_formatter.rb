# frozen_string_literal: true

require_relative 'base_formatter'
require_relative '../json_helper'

module AmazingPrint
  module Formatters
    class HashFormatter < BaseFormatter
      include AmazingPrint::JSONHelper

      VALID_HASH_FORMATS = %i[json rocket symbol].freeze

      class InvalidHashFormatError < StandardError; end

      attr_reader :hash, :inspector, :options

      def initialize(hash, inspector)
        super()
        @hash = hash
        @inspector = inspector
        @options = inspector.options

        return if VALID_HASH_FORMATS.include?(options[:hash_format])

        raise(InvalidHashFormatError, "Invalid hash_format: #{options[:hash_format].inspect}. " \
                                      "Must be one of #{VALID_HASH_FORMATS}")
      end

      def format
        if hash.empty?
          empty_hash
        elsif multiline_hash?
          multiline_hash
        else
          simple_hash
        end
      end

      private

      def empty_hash
        '{}'
      end

      def multiline_hash?
        options[:multiline]
      end

      def multiline_hash
        ["{\n", printable_hash.join(",\n"), "\n#{outdent}}"].join
      end

      def simple_hash
        "{ #{printable_hash.join(', ')} }"
      end

      def printable_hash
        data = printable_keys
        width = left_width(data)

        data.map! do |key, value|
          indented do
            case options[:hash_format]
            when :json
              json_syntax(key, value, width)
            when :rocket
              pre_ruby19_syntax(key, value, width)
            when :symbol
              ruby19_syntax(key, value, width)
            end
          end
        end

        should_be_limited? ? limited(data, width, is_hash: true) : data
      end

      def left_width(keys)
        result = max_key_width(keys)
        result += indentation if options[:indent].positive?
        result
      end

      def key_size(key)
        return key.inspect.size if symbol?(key)

        if options[:html]
          single_line { inspector.awesome(key) }.size
        else
          plain_single_line { inspector.awesome(key) }.size
        end
      end

      def max_key_width(keys)
        keys.map { |key, _value| key_size(key) }.max || 0
      end

      def printable_keys
        keys = hash.keys

        keys.sort! { |a, b| a.to_s <=> b.to_s } if options[:sort_keys]

        keys.map! do |key|
          single_line do
            [key, hash[key]]
          end
        end
      end

      def string?(key)
        key[0] == '"' && key[-1] == '"'
      end

      def symbol?(key)
        key.is_a?(Symbol)
      end

      def json_format?
        options[:hash_format] == :json
      end

      def json_syntax(key, value, width)
        unless defined?(JSON)
          warn 'JSON is not defined. Defaulting hash format to symbol'
          return ruby19_syntax(key, value, width)
        end

        formatted_key = json_awesome(key, is_key: true)
        formatted_value = json_awesome(value)

        "#{align(formatted_key, width)}#{colorize(': ', :hash)}#{formatted_value}"
      end

      def ruby19_syntax(key, value, width)
        return pre_ruby19_syntax(key, value, width) unless symbol?(key)

        # Move the colon to the right side of the symbol
        key_string = key.inspect.include?('"') ? key.inspect.sub(':', '') : key.to_s
        awesome_key = inspector.awesome(key).sub(/#{Regexp.escape(key.inspect)}/, "#{key_string}:")

        "#{align(awesome_key, width)} #{inspector.awesome(value)}"
      end

      def pre_ruby19_syntax(key, value, width)
        awesome_key = single_line { inspector.awesome(key) }
        "#{align(awesome_key, width)}#{colorize(' => ', :hash)}#{inspector.awesome(value)}"
      end

      def plain_single_line(&)
        plain = options[:plain]
        options[:plain] = true
        single_line(&)
      ensure
        options[:plain] = plain
      end

      def single_line
        multiline = options[:multiline]
        options[:multiline] = false
        yield
      ensure
        options[:multiline] = multiline
      end
    end
  end
end

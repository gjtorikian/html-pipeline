# typed: strict
# frozen_string_literal: true

module Tapioca
  module ConfigHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Thor }

    sig { returns(String) }
    attr_reader :command_name

    sig { returns(Thor::CoreExt::HashWithIndifferentAccess) }
    attr_reader :defaults

    sig { params(args: T.untyped, local_options: T.untyped, config: T.untyped).void }
    def initialize(args = [], local_options = {}, config = {})
      # Store current command
      command = config[:current_command]
      command_options = config[:command_options]
      @command_name = T.let(command.name, String)
      @merged_options = T.let(nil, T.nilable(Thor::CoreExt::HashWithIndifferentAccess))
      @defaults = T.let(Thor::CoreExt::HashWithIndifferentAccess.new, Thor::CoreExt::HashWithIndifferentAccess)

      # Filter command options unless we are handling the help command.
      # This is so that the defaults are printed
      filter_defaults(command_options) unless command_name == "help"

      super
    end

    sig { returns(Thor::CoreExt::HashWithIndifferentAccess) }
    def options
      @merged_options ||= begin
        original_options = super
        config_options = config_options(original_options)

        merge_options(defaults, config_options, original_options)
      end
    end

    private

    sig { params(options: T::Hash[Symbol, Thor::Option]).void }
    def filter_defaults(options)
      options.each do |key, option|
        # Store the value of the current default in our defaults hash
        defaults[key] = option.default
        # Remove the default value from the option
        option.instance_variable_set(:@default, nil)
      end
    end

    sig { params(options: Thor::CoreExt::HashWithIndifferentAccess).returns(Thor::CoreExt::HashWithIndifferentAccess) }
    def config_options(options)
      config_file = options[:config]
      config = {}

      if File.exist?(config_file)
        config = YAML.load_file(config_file, fallback: {})
      end

      validate_config!(config_file, config)

      Thor::CoreExt::HashWithIndifferentAccess.new(config[command_name] || {})
    end

    sig { params(config_file: String, config: T::Hash[T.untyped, T.untyped]).void }
    def validate_config!(config_file, config)
      # To ensure that this is not re-entered, we mark during validation
      return if @validating_config

      @validating_config = T.let(true, T.nilable(T::Boolean))

      commands = T.cast(self, Thor).class.commands

      errors = config.flat_map do |config_key, config_options|
        command = commands[config_key.to_s]

        unless command
          next build_error("unknown key `#{config_key}`")
        end

        validate_config_options(command.options, config_key, config_options || {})
      end.compact

      unless errors.empty?
        raise Thor::Error, build_error_message(config_file, errors)
      end
    ensure
      @validating_config = false
    end

    sig do
      params(
        command_options: T::Hash[Symbol, Thor::Option],
        config_key: String,
        config_options: T::Hash[T.untyped, T.untyped],
      ).returns(T::Array[ConfigError])
    end
    def validate_config_options(command_options, config_key, config_options)
      config_options.filter_map do |config_option_key, config_option_value|
        command_option = command_options[config_option_key.to_sym]
        error_msg = "unknown option `#{config_option_key}` for key `#{config_key}`"
        next build_error(error_msg) unless command_option

        config_option_value_type = case config_option_value
        when FalseClass, TrueClass
          :boolean
        when Numeric
          :numeric
        when Hash
          :hash
        when Array
          :array
        when String
          :string
        else
          :object
        end

        error_msg = "invalid value for option `#{config_option_key}` for key `#{config_key}` - expected " \
          "`#{command_option.type.capitalize}` but found #{config_option_value_type.capitalize}"
        next build_error(error_msg) unless config_option_value_type == command_option.type

        case config_option_value_type
        when :array
          error_msg = "invalid value for option `#{config_option_key}` for key `#{config_key}` - expected " \
            "`Array[String]` but found `#{config_option_value}`"
          next build_error(error_msg) unless config_option_value.all? { |v| v.is_a?(String) }
        when :hash
          error_msg = "invalid value for option `#{config_option_key}` for key `#{config_key}` - expected " \
            "`Hash[String, String]` but found `#{config_option_value}`"
          values_to_validate = config_option_value.keys
          values_to_validate += config_option_value.values
          all_strings = values_to_validate.all? { |v| v.is_a?(String) }
          next build_error(error_msg) unless all_strings
        end
      end
    end

    class ConfigErrorMessagePart < T::Struct
      const :message, String
      const :colors, T::Array[Symbol]
    end

    class ConfigError < T::Struct
      const :message_parts, T::Array[ConfigErrorMessagePart]
    end

    sig { params(msg: String).returns(ConfigError) }
    def build_error(msg)
      parts = msg.split(/(`[^`]+` ?)/)

      message_parts = parts.map do |part|
        match = part.match(/`([^`]+)`( ?)/)

        if match
          ConfigErrorMessagePart.new(
            message: "#{match[1]}#{match[2]}",
            colors: [:bold, :blue],
          )
        else
          ConfigErrorMessagePart.new(
            message: part,
            colors: [:yellow],
          )
        end
      end

      ConfigError.new(
        message_parts: message_parts,
      )
    end

    sig { params(config_file: String, errors: T::Array[ConfigError]).returns(String) }
    def build_error_message(config_file, errors)
      error_messages = errors.map do |error|
        "- " + error.message_parts.map do |part|
          T.unsafe(self).set_color(part.message, *part.colors)
        end.join
      end.join("\n")

      <<~ERROR
        #{set_color("\nConfiguration file", :red)} #{set_color(config_file, :blue, :bold)} #{set_color("has the following errors:", :red)}

        #{error_messages}
      ERROR
    end

    sig do
      params(options: T.nilable(Thor::CoreExt::HashWithIndifferentAccess))
        .returns(Thor::CoreExt::HashWithIndifferentAccess)
    end
    def merge_options(*options)
      merged = options.each_with_object({}) do |option, result|
        result.merge!(option || {}) do |_, this_val, other_val|
          if this_val.is_a?(Hash) && other_val.is_a?(Hash)
            Thor::CoreExt::HashWithIndifferentAccess.new(this_val.merge(other_val))
          else
            other_val
          end
        end
      end

      Thor::CoreExt::HashWithIndifferentAccess.new(merged)
    end
  end
end

# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    # Parse Sorbet config files
    #
    # Parses a Sorbet config file:
    #
    # ```ruby
    # config = Spoom::Sorbet::Config.parse_file("sorbet/config")
    # puts config.paths   # "."
    # ```
    #
    # Parses a Sorbet config string:
    #
    # ```ruby
    # config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
    #   a
    #   --file=b
    #   --ignore=c
    # CONFIG
    # puts config.paths   # "a", "b"
    # puts config.ignore  # "c"
    # ```
    class Config
      DEFAULT_ALLOWED_EXTENSIONS = [".rb", ".rbi"].freeze #: Array[String]

      #: Array[String]
      attr_accessor :paths, :ignore, :allowed_extensions

      #: bool
      attr_accessor :no_stdlib

      #: -> void
      def initialize
        @paths = [] #: Array[String]
        @ignore = [] #: Array[String]
        @allowed_extensions = [] #: Array[String]
        @no_stdlib = false #: bool
      end

      #: -> Config
      def copy
        new_config = Sorbet::Config.new
        new_config.paths.concat(@paths)
        new_config.ignore.concat(@ignore)
        new_config.allowed_extensions.concat(@allowed_extensions)
        new_config.no_stdlib = @no_stdlib
        new_config
      end

      # Returns self as a string of options that can be passed to Sorbet
      #
      # Example:
      # ~~~rb
      # config = Sorbet::Config.new
      # config.paths << "/foo"
      # config.paths << "/bar"
      # config.ignore << "/baz"
      # config.allowed_extensions << ".rb"
      #
      # puts config.options_string # "/foo /bar --ignore /baz --allowed-extension .rb"
      # ~~~
      #: -> String
      def options_string
        opts = []
        opts.concat(paths.map { |p| "'#{p}'" })
        opts.concat(ignore.map { |p| "--ignore '#{p}'" })
        opts.concat(allowed_extensions.map { |ext| "--allowed-extension '#{ext}'" })
        opts << "--no-stdlib" if @no_stdlib
        opts.join(" ")
      end

      class << self
        #: (String sorbet_config_path) -> Spoom::Sorbet::Config
        def parse_file(sorbet_config_path)
          parse_string(File.read(sorbet_config_path))
        end

        #: (String sorbet_config) -> Spoom::Sorbet::Config
        def parse_string(sorbet_config)
          config = Config.new
          state = nil #: Symbol?
          sorbet_config.each_line do |line|
            line = line.strip
            case line
            when /^--allowed-extension$/
              state = :extension
              next
            when /^--allowed-extension=/
              config.allowed_extensions << parse_option(line)
              next
            when /^--ignore$/
              state = :ignore
              next
            when /^--ignore=/
              config.ignore << parse_option(line)
              next
            when /^--file$/
              next
            when /^--file=/
              config.paths << parse_option(line)
              next
            when /^--dir$/
              next
            when /^--dir=/
              config.paths << parse_option(line)
              next
            when /^--no-stdlib$/
              config.no_stdlib = true
              next
            when /^--.*=/
              next
            when /^--/
              state = :skip
            when /^-.*=?/
              next
            when /^#/
              next
            when /^$/
              next
            else
              case state
              when :ignore
                config.ignore << line
              when :extension
                config.allowed_extensions << line
              when :skip
                # nothing
              else
                config.paths << line
              end
              state = nil
            end
          end
          config
        end

        private

        #: (String line) -> String
        def parse_option(line)
          T.must(line.split("=").last).strip
        end
      end
    end
  end
end

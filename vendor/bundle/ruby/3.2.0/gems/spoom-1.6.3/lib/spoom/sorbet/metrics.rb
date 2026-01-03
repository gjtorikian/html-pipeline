# typed: strict
# frozen_string_literal: true

require_relative "sigils"

module Spoom
  module Sorbet
    module MetricsParser
      DEFAULT_PREFIX = "ruby_typer.unknown."

      class << self
        #: (String path, ?String prefix) -> Hash[String, Integer]
        def parse_file(path, prefix = DEFAULT_PREFIX)
          parse_string(File.read(path), prefix)
        end

        #: (String string, ?String prefix) -> Hash[String, Integer]
        def parse_string(string, prefix = DEFAULT_PREFIX)
          parse_hash(JSON.parse(string), prefix)
        end

        #: (Hash[String, untyped] obj, ?String prefix) -> Hash[String, Integer]
        def parse_hash(obj, prefix = DEFAULT_PREFIX)
          obj["metrics"].each_with_object(Hash.new(0)) do |metric, metrics|
            name = metric["name"]
            name = name.sub(prefix, "")
            metrics[name] = metric["value"] || 0
          end
        end
      end
    end
  end
end

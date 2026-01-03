# frozen_string_literal: true

require_relative "commonmarker/extension"

require "commonmarker/utils"
require "commonmarker/node"
require "commonmarker/config"
require "commonmarker/renderer"
require "commonmarker/version"

module Commonmarker
  class << self
    # Public: Parses a CommonMark string into an HTML string.
    #
    # text - A {String} of text
    # options - A {Hash} of render, parse, and extension options to transform the text.
    #
    # Returns the `parser` node.
    def parse(text, options: Commonmarker::Config::OPTIONS)
      raise TypeError, "text must be a String; got a #{text.class}!" unless text.is_a?(String)
      raise TypeError, "text must be UTF-8 encoded; got #{text.encoding}!" unless text.encoding.name == "UTF-8"
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      opts = Config.process_options(options)

      commonmark_parse(text, options: opts)
    end

    # Public: Parses a CommonMark string into an HTML string.
    #
    # text - A {String} of text
    # options - A {Hash} of render, parse, and extension options to transform the text.
    # plugins - A {Hash} of additional plugins.
    #
    # Returns a {String} of converted HTML.
    def to_html(text, options: Commonmarker::Config::OPTIONS, plugins: Commonmarker::Config::PLUGINS)
      raise TypeError, "text must be a String; got a #{text.class}!" unless text.is_a?(String)
      raise TypeError, "text must be UTF-8 encoded; got #{text.encoding}!" unless text.encoding.name == "UTF-8"
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      opts = Config.process_options(options)
      plugins = Config.process_plugins(plugins)

      commonmark_to_html(text, options: opts, plugins: plugins)
    end
  end
end

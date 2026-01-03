# frozen_string_literal: true

require "commonmarker/node/ast"
require "commonmarker/node/inspect"

module Commonmarker
  class Node
    include Enumerable
    include Inspect

    # Public: An iterator that "walks the tree," descending into children recursively.
    #
    # blk - A {Proc} representing the action to take for each child
    def walk(&block)
      return enum_for(:walk) unless block

      yield self
      each do |child|
        child.walk(&block)
      end
    end

    # Public: Iterate over the children (if any) of the current pointer.
    def each
      return enum_for(:each) unless block_given?

      child = first_child
      while child
        next_child = child.next_sibling
        yield child
        child = next_child
      end
    end

    # Public: Converts a node to an HTML string.
    #
    # options - A {Hash} of render, parse, and extension options to transform the text.
    # plugins - A {Hash} of additional plugins.
    #
    # Returns a {String} of HTML.
    def to_html(options: Commonmarker::Config::OPTIONS, plugins: Commonmarker::Config::PLUGINS)
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      opts = Config.process_options(options)
      plugins = Config.process_plugins(plugins)

      node_to_html(options: opts, plugins: plugins).force_encoding("utf-8")
    end

    # Public: Convert the node to a CommonMark string.
    #
    # options - A {Symbol} or {Array of Symbol}s indicating the render options
    # plugins - A {Hash} of additional plugins.
    #
    # Returns a {String}.
    def to_commonmark(options: Commonmarker::Config::OPTIONS, plugins: Commonmarker::Config::PLUGINS)
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      opts = Config.process_options(options)
      plugins = Config.process_plugins(plugins)

      node_to_commonmark(options: opts, plugins: plugins).force_encoding("utf-8")
    end
  end
end

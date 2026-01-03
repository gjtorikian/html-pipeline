# frozen_string_literal: true

module Commonmarker
  module Config
    # For details, see
    # https://github.com/kivikakk/comrak/blob/162ef9354deb2c9b4a4e05be495aa372ba5bb696/src/main.rs#L201
    OPTIONS = {
      parse: {
        smart: false,
        default_info_string: "",
        relaxed_tasklist_matching: false,
        relaxed_autolinks: false,
      }.freeze,
      render: {
        hardbreaks: true,
        github_pre_lang: true,
        full_info_string: false,
        width: 80,
        unsafe: false,
        escape: false,
        sourcepos: false,
        escaped_char_spans: true,
        ignore_setext: false,
        ignore_empty_links: false,
        gfm_quirks: false,
        prefer_fenced: false,
      }.freeze,
      extension: {
        strikethrough: true,
        tagfilter: true,
        table: true,
        autolink: true,
        tasklist: true,
        superscript: false,
        header_ids: "",
        footnotes: false,
        description_lists: false,
        front_matter_delimiter: "",
        multiline_block_quotes: false,
        math_dollars: false,
        math_code: false,
        shortcodes: true,
        wikilinks_title_before_pipe: false,
        wikilinks_title_after_pipe: false,
        underline: false,
        spoiler: false,
        greentext: false,
        subscript: false,
        alerts: false,
      }.freeze,
      format: [:html].freeze,
    }.freeze

    PLUGINS = {
      syntax_highlighter: {
        theme: "base16-ocean.dark",
        path: "",
      },
    }

    class << self
      include Commonmarker::Utils

      def process_options(options)
        {
          parse: process_parse_options(options[:parse].dup),
          render: process_render_options(options[:render].dup),
          extension: process_extension_options(options[:extension].dup),
        }
      end

      def process_plugins(plugins)
        {
          syntax_highlighter: process_syntax_highlighter_plugin(plugins&.fetch(:syntax_highlighter, nil)),
        }
      end
    end

    [:parse, :render, :extension].each do |type|
      define_singleton_method :"process_#{type}_options" do |options|
        Commonmarker::Config::OPTIONS[type].each_with_object({}) do |(key, value), hash|
          if options.nil? || !options.key?(key) # option not provided, use the default
            hash[key] = value
            next
          end

          if options[key].nil? # # option explicitly not included, remove it
            options.delete(key)
            next
          end

          hash[key] = fetch_kv(options, key, value, type)
        end
      end
    end

    define_singleton_method :process_syntax_highlighter_plugin do |options|
      return if options.nil? # plugin explicitly nil, remove it

      raise TypeError, "Expected a Hash for syntax_highlighter plugin, got #{options.class}" unless options.is_a?(Hash)
      raise TypeError, "Expected a Hash for syntax_highlighter plugin, got nothing" if options.empty?

      Commonmarker::Config::PLUGINS[:syntax_highlighter].merge(options)
    end
  end
end

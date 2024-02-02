# frozen_string_literal: true

require "selma"

class HTMLPipeline
  # A special filter with sanization routines and allowlists. This module defines
  # what HTML is allowed in user provided content and fixes up issues with
  # unbalanced tags and whatnot.
  #
  # See the Selma docs for more information on the underlying library:
  #
  # https://github.com/gjtorikian/selma/#readme
  #
  # This filter does not write additional information to the context.
  class SanitizationFilter
    VALID_PROTOCOLS = Selma::Sanitizer::Config::VALID_PROTOCOLS.dup

    # The main sanitization allowlist. Only these elements and attributes are
    # allowed through by default.
    DEFAULT_CONFIG = Selma::Sanitizer::Config.freeze_config({
      elements: [
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "br",
        "b",
        "i",
        "strong",
        "em",
        "a",
        "pre",
        "code",
        "img",
        "tt",
        "div",
        "ins",
        "del",
        "sup",
        "sub",
        "p",
        "picture",
        "ol",
        "ul",
        "table",
        "thead",
        "tbody",
        "tfoot",
        "blockquote",
        "dl",
        "dt",
        "dd",
        "kbd",
        "q",
        "samp",
        "var",
        "hr",
        "ruby",
        "rt",
        "rp",
        "li",
        "tr",
        "td",
        "th",
        "s",
        "strike",
        "summary",
        "details",
        "caption",
        "figure",
        "figcaption",
        "abbr",
        "bdo",
        "cite",
        "dfn",
        "mark",
        "small",
        "source",
        "span",
        "time",
        "wbr",
      ],

      attributes: {
        "a" => ["href"],
        "img" => ["src", "longdesc", "loading", "alt"],
        "div" => ["itemscope", "itemtype"],
        "blockquote" => ["cite"],
        "del" => ["cite"],
        "ins" => ["cite"],
        "q" => ["cite"],
        "source" => ["srcset"],
        all: [
          "abbr",
          "accept",
          "accept-charset",
          "accesskey",
          "action",
          "align",
          "alt",
          "aria-describedby",
          "aria-hidden",
          "aria-label",
          "aria-labelledby",
          "axis",
          "border",
          "char",
          "charoff",
          "charset",
          "checked",
          "clear",
          "cols",
          "colspan",
          "compact",
          "coords",
          "datetime",
          "dir",
          "disabled",
          "enctype",
          "for",
          "frame",
          "headers",
          "height",
          "hreflang",
          "hspace",
          "id",
          "ismap",
          "label",
          "lang",
          "maxlength",
          "media",
          "method",
          "multiple",
          "name",
          "nohref",
          "noshade",
          "nowrap",
          "open",
          "progress",
          "prompt",
          "readonly",
          "rel",
          "rev",
          "role",
          "rows",
          "rowspan",
          "rules",
          "scope",
          "selected",
          "shape",
          "size",
          "span",
          "start",
          "summary",
          "tabindex",
          "title",
          "type",
          "usemap",
          "valign",
          "value",
          "width",
          "itemprop",
        ],
      },
      protocols: {
        "a" => { "href" => Selma::Sanitizer::Config::VALID_PROTOCOLS }.freeze,
        "blockquote" => { "cite" => ["http", "https", :relative].freeze },
        "del" => { "cite" => ["http", "https", :relative].freeze },
        "ins" => { "cite" => ["http", "https", :relative].freeze },
        "q" => { "cite" => ["http", "https", :relative].freeze },
        "img" => {
          "src" => ["http", "https", :relative].freeze,
          "longdesc" => ["http", "https", :relative].freeze,
        },
      },
    })

    class << self
      def call(html, config)
        raise ArgumentError, "html must be a String, not #{html.class}" unless html.is_a?(String)
        raise ArgumentError, "config must be a Hash, not #{config.class}" unless config.is_a?(Hash)

        sanitization_config = Selma::Sanitizer.new(config)
        Selma::Rewriter.new(sanitizer: sanitization_config).rewrite(html)
      end
    end
  end
end

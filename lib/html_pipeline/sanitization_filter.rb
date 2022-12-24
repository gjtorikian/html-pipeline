# frozen_string_literal: true

HTMLPipeline.require_dependency("sanitize", "SanitizationFilter")

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
    LISTS     = Set.new(["ul", "ol"].freeze)
    LIST_ITEM = "li"

    # List of table child elements. These must be contained by a <table> element
    # or they are not allowed through. Otherwise they can be used to break out
    # of places we're using tables to contain formatted user content (like pull
    # request review comments).
    TABLE_ITEMS = Set.new(["tr", "td", "th"].freeze)
    TABLE = "table"
    TABLE_SECTIONS = Set.new(["thead", "tbody", "tfoot"].freeze)

    # These schemes are the only ones allowed in <a href> attributes by default.
    PROTOCOLS = ["http", "https", "mailto", "xmpp", :relative, "irc", "ircs"].freeze

    # The main sanitization allowlist. Only these elements and attributes are
    # allowed through by default.
    DEFAULT_CONFIG = {
      elements: ["h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8", "br", "b", "i", "strong", "em", "a", "pre", "code", "img", "tt", "div", "ins", "del", "sup", "sub", "p", "ol", "ul", "table", "thead", "tbody", "tfoot", "blockquote", "dl", "dt", "dd", "kbd", "q", "samp", "var", "hr", "ruby", "rt", "rp", "li", "tr", "td", "th", "s", "strike", "summary", "details", "caption", "figure", "figcaption", "abbr", "bdo", "cite", "dfn", "mark", "small", "span", "time", "wbr"].freeze,
      remove_contents: ["script"].freeze,
      attributes: {
        "a" => ["href"].freeze,
        "img" => ["src", "longdesc"].freeze,
        "div" => ["itemscope", "itemtype"].freeze,
        "blockquote" => ["cite"].freeze,
        "del" => ["cite"].freeze,
        "ins" => ["cite"].freeze,
        "q" => ["cite"].freeze,
        all: ["abbr", "accept", "accept-charset", "accesskey", "action", "align", "alt", "aria-describedby", "aria-hidden", "aria-label", "aria-labelledby", "axis", "border", "cellpadding", "cellspacing", "char", "charoff", "charset", "checked", "clear", "cols", "colspan", "color", "compact", "coords", "datetime", "dir", "disabled", "enctype", "for", "frame", "headers", "height", "hreflang", "hspace", "ismap", "label", "lang", "maxlength", "media", "method", "multiple", "name", "nohref", "noshade", "nowrap", "open", "progress", "prompt", "readonly", "rel", "rev", "role", "rows", "rowspan", "rules", "scope", "selected", "shape", "size", "span", "start", "summary", "tabindex", "target", "title", "type", "usemap", "valign", "value", "vspace", "width", "itemprop"].freeze,
      }.freeze,
      protocols: {
        "a" => { "href" => PROTOCOLS }.freeze,
        "blockquote" => { "cite" => ["http", "https", :relative].freeze },
        "del" => { "cite" => ["http", "https", :relative].freeze },
        "ins" => { "cite" => ["http", "https", :relative].freeze },
        "q" => { "cite" => ["http", "https", :relative].freeze },
        "img" => {
          "src" => ["http", "https", :relative].freeze,
          "longdesc" => ["http", "https", :relative].freeze,
        }.freeze,
      },
      transformers: [
        # Top-level <li> elements are removed because they can break out of
        # containing markup.
        lambda { |env|
          name = env[:node_name]
          node = env[:node]
          node.replace(node.children) if name == LIST_ITEM && node.ancestors.none? { |n| LISTS.include?(n.name) }
        },

        # Table child elements that are not contained by a <table> are removed.
        lambda { |env|
          name = env[:node_name]
          node = env[:node]
          node.replace(node.children) if (TABLE_SECTIONS.include?(name) || TABLE_ITEMS.include?(name)) && node.ancestors.none? { |n| n.name == TABLE }
        },
      ].freeze,
    }.freeze

    def self.call(html, config)
      raise ArgumentError, "html must be a String, not #{html.class}" unless html.is_a?(String)
      raise ArgumentError, "config must be a Hash, not #{config.class}" unless config.is_a?(Hash)

      sanitization_config = Selma::Sanitizer.new(config)
      Selma::Rewriter.new(sanitizer: sanitization_config).rewrite(html)
    end
  end
end

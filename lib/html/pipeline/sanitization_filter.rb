begin
  require "sanitize"
  require "sanitize/whitelist"
rescue LoadError => _
  abort "Missing dependency 'sanitize' for SanitizationFilter. See README.md for details."
end

module HTML
  class Pipeline
    # HTML filter with sanization routines and whitelists. This module defines
    # what HTML is allowed in user provided content and fixes up issues with
    # unbalanced tags and whatnot.
    #
    # See the Sanitize docs for more information on the underlying library:
    #
    # https://github.com/rgrove/sanitize/#readme
    #
    # Context options:
    #   :whitelist      - The sanitizer whitelist configuration to use. This
    #                     can be one of the options constants defined in this
    #                     class or a custom sanitize options hash.
    #   :anchor_schemes - The URL schemes to allow in <a href> attributes. The
    #                     default set is provided in the ANCHOR_SCHEMES
    #                     constant in this class. If passed, this overrides any
    #                     schemes specified in the whitelist configuration.
    #
    # This filter does not write additional information to the context.
    class SanitizationFilter < Filter
      # These schemes are the only ones allowed in <a href> attributes by default.
      ANCHOR_SCHEMES = ['http', 'https', 'mailto', :relative, 'github-windows', 'github-mac'].freeze

      # The main sanitization whitelist. Only these elements and attributes are
      # allowed through by default.
      WHITELIST = Sanitize::Whitelist.new do
        remove "script"

        allow %w(
          h1 h2 h3 h4 h5 h6 h7 h8 br b i strong em a pre code img tt div ins del
          sup sub p ol ul table thead tbody tfoot blockquote dl dt dd kbd q samp
          var hr ruby rt rp li tr td th s strike
        )

        element("a").allow("href").protocols(ANCHOR_SCHEMES)
        element("img").allow("src").protocols(['http', 'https', :relative])
        element("div").allow(%w(itemscope itemtype))

        element(:all).allow(
          %w(abbr accept accept-charset accesskey action align alt axis border
          cellpadding cellspacing char charoff charset checked cite clear cols
          colspan color compact coords datetime details dir disabled enctype for
          frame headers height hreflang hspace ismap label lang longdesc
          maxlength media method multiple name nohref noshade nowrap prompt
          readonly rel rev rows rowspan rules scope selected shape size span
          start summary tabindex target title type usemap valign value vspace
          width itemprop)
        )

        # Top-level <li> elements are removed because they can break out of
        # containing markup.
        LISTS     = Set.new(%w(ul ol).freeze)
        LIST_ITEM = 'li'.freeze
        transform do |env|
          name, node = env[:node_name], env[:node]
          if name == LIST_ITEM && !node.ancestors.any?{ |n| LISTS.include?(n.name) }
            node.replace(node.children)
          end
        end

        # Table child elements that are not contained by a <table> are removed.
        # Otherwise they can be used to break out of containing markup.
        TABLE_ITEMS = Set.new(%w(tr td th).freeze)
        TABLE = 'table'.freeze
        TABLE_SECTIONS = Set.new(%w(thead tbody tfoot).freeze)
        transform do |env|
          name, node = env[:node_name], env[:node]
          if (TABLE_SECTIONS.include?(name) || TABLE_ITEMS.include?(name)) && !node.ancestors.any? { |n| n.name == TABLE }
            node.replace(node.children)
          end
        end
      end

      # A more limited sanitization whitelist. This includes all attributes,
      # protocols, and transformers from WHITELIST but with a more locked down
      # set of allowed elements.
      LIMITED = Sanitize::Whitelist.new do
        allow %w(b i strong em a pre code img ins del sup sub p ol ul li)
      end

      # Strip all HTML tags from the document.
      FULL = Sanitize::Whitelist.new

      # Sanitize markup using the Sanitize library.
      def call
        Sanitize.clean_node!(doc, whitelist.to_hash)
      end

      # The whitelist to use when sanitizing. This can be passed in the context
      # hash to the filter but defaults to WHITELIST constant value above.
      def whitelist
        whitelist = context[:whitelist] || WHITELIST

        if anchor_schemes = context[:anchor_schemes]
          whitelist = whitelist.dup do
            element("a").allow("href").protocols(anchor_schemes)
          end
        end

        whitelist
      end
    end
  end
end

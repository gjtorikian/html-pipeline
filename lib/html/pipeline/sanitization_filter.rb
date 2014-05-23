begin
  require "sanitize"
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

      LISTS     = Set.new(%w(ol ul).freeze)
      LIST_ITEM = 'li'.freeze

      DEF_LIST      = 'dl'.freeze
      DEF_LIST_ITEMS = Set.new(%w(dt dd).freeze)

      # List of table child elements. These must be contained by a <table> element
      # or they are not allowed through. Otherwise they can be used to break out
      # of places we're using tables to contain formatted user content (like pull
      # request review comments).
      TABLE = 'table'.freeze
      TABLE_SECTIONS = Set.new(%w(caption colgroup thead tbody tfoot).freeze)
      TABLE_ITEMS = Set.new(%w(col tr td th).freeze)

      # The main sanitization whitelist. Only these elements and attributes are
      # allowed through by default.
      WHITELIST = {
        :elements => %w(
          # block elements (with mixed content)
          div
          h1 h2 h3 h4 h5 h6 h7 h8
          blockquote p
          pre
          # + section heading summary nav content ?
          #  block elements (with block-structured content)
          ol ul li
          dl dt dd
          table caption
          colgroup thead tbody tfoot
          col tr th td
          # block elements (without content)
          hr
          # inline or block elements (with mixed content)
          bdi bdo a
          # inline elements (with inline content)
          span q
          b strong
          i em var
          u ins
          s strike del
          tt code kbd samp
          sup sub
          small big
          ruby rt rp
          # unline elements (without content)
          br img
        ),
        :remove_contents => ['script'],
        :attributes => {
          'a' => ['href'],
          'img' => ['src'],
          'div' => ['itemscope', 'itemtype'],
          :all  => ['abbr', 'accept', 'accept-charset',
                    'accesskey', 'action', 'align', 'alt', 'axis',
                    'border', 'cellpadding', 'cellspacing', 'char',
                    'charoff', 'charset', 'checked', 'cite',
                    'clear', 'cols', 'colspan', 'color',
                    'compact', 'coords', 'datetime', 'dir',
                    'disabled', 'enctype', 'for', 'frame',
                    'headers', 'height', 'hreflang',
                    'hspace', 'ismap', 'label', 'lang',
                    'longdesc', 'maxlength', 'media', 'method',
                    'multiple', 'name', 'nohref', 'noshade',
                    'nowrap', 'prompt', 'readonly', 'rel', 'rev',
                    'rows', 'rowspan', 'rules', 'scope',
                    'selected', 'shape', 'size', 'span',
                    'start', 'summary', 'tabindex', 'target',
                    'title', 'type', 'usemap', 'valign', 'value',
                    'vspace', 'width', 'itemprop']
        },
        :protocols => {
          'a'   => {'href' => ANCHOR_SCHEMES},
          'img' => {'src'  => ['http', 'https', :relative]}
        },
        :transformers => [
          # Top-level <li> elements are placed in a default unordered list
          # because they can break out ofcontaining markup.
          lambda { |env|
            name, node = env[:node_name], env[:node]
            if LIST_ITEM == name
            && !node.ancestors.any?{ |n| LISTS.include?(n.name) }
              node.replace(node.children)
            end
          },

          # Top-level <li> elements are removed because they can break out of
          # containing markup.
          lambda { |env|
            name, node = env[:node_name], env[:node]
            if DEF_LIST_ITEMS.include?(name)
            && !node.ancestors.any?{ |n| DEF_LIST == n.name }
              node.replace(node.children)
            end
          },

          # Table child elements that are not contained by a <table> are removed.
          lambda { |env|
            name, node = env[:node_name], env[:node]
            if (TABLE_SECTIONS.include?(name) || TABLE_ITEMS.include?(name))
            && !node.ancestors.any?{ |n| TABLE == n.name }
              node.replace(node.children)
            end
          }
        ]
      }

      # A more limited sanitization whitelist. This includes all attributes,
      # protocols, and transformers from WHITELIST but with a more locked down
      # set of allowed elements.
      LIMITED = WHITELIST.merge(
        :elements => %w(
          p
          pre
          ol ul li
          b strong
          i em
          u ins
          s del 
          tt code
          sup sub
          a img
        )
      )

      # Strip all HTML tags from the document.
      FULL = { :elements => [] }

      # Sanitize markup using the Sanitize library.
      def call
        Sanitize.clean_node!(doc, whitelist)
      end

      # The whitelist to use when sanitizing. This can be passed in the context
      # hash to the filter but defaults to WHITELIST constant value above.
      def whitelist
        whitelist = context[:whitelist] || WHITELIST
        anchor_schemes = context[:anchor_schemes]
        if anchor_schemes
          whitelist = whitelist.dup
          whitelist[:protocols] = (whitelist[:protocols] || {}).dup
          whitelist[:protocols]['a'] = (whitelist[:protocols]['a'] || {}).merge('href' => anchor_schemes)
        end
        return whitelist
      end
    end
  end
end

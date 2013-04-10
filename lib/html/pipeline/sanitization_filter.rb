require 'sanitize'

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
    #   :whitelist - The sanitizer whitelist configuration to use. This can be one
    #                of the options constants defined in this class or a custom
    #                sanitize options hash.
    #
    # This filter does not write additional information to the context.
    class SanitizationFilter < Filter
      LISTS     = Set.new(%w(ul ol).freeze)
      LIST_ITEM = 'li'.freeze

      # List of table child elements. These must be contained by a <table> element
      # or they are not allowed through. Otherwise they can be used to break out
      # of places we're using tables to contain formatted user content (like pull
      # request review comments).
      TABLE_ITEMS = Set.new(%w(tr td th).freeze)
      TABLE       = 'table'.freeze

      # The main sanitization whitelist. Only these elements and attributes are
      # allowed through by default.
      WHITELIST = {
        :elements => %w(
          h1 h2 h3 h4 h5 h6 h7 h8 br b i strong em a pre code img tt
          div ins del sup sub p ol ul table blockquote dl dt dd
          kbd q samp var hr ruby rt rp li tr td th
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
          'a'   => {'href' => ['http', 'https', 'mailto', :relative, 'github-windows', 'github-mac']},
          'img' => {'src'  => ['http', 'https', :relative]}
        },
        :transformers => [
          # Top-level <li> elements are removed because they can break out of
          # containing markup.
          lambda { |env|
            name, node = env[:node_name], env[:node]
            if name == LIST_ITEM && !node.ancestors.any?{ |n| LISTS.include?(n.name) }
              node.replace(node.children)
            end
          },

          # Table child elements that are not contained by a <table> are removed.
          lambda { |env|
            name, node = env[:node_name], env[:node]
            if TABLE_ITEMS.include?(name) && !node.ancestors.any? { |n| n.name == TABLE }
              node.replace(node.children)
            end
          }
        ]
      }

      # A more limited sanitization whitelist. This includes all attributes,
      # protocols, and transformers from WHITELIST but with a more locked down
      # set of allowed elements.
      LIMITED = WHITELIST.merge(
        :elements => %w(b i strong em a pre code img ins del sup sub p ol ul li))

      # Strip all HTML tags from the document.
      FULL = { :elements => [] }

      # Sanitize markup using the Sanitize library.
      def call
        Sanitize.clean_node!(doc, whitelist)
      end

      # The whitelist to use when sanitizing. This can be passed in the context
      # hash to the filter but defaults to WHITELIST constant value above.
      def whitelist
        context[:whitelist] || WHITELIST
      end
    end
  end
end
require 'sanitize'

module GitHub::HTML
  # HTML filter with sanization routines and whitelists. This module defines
  # what HTML is allowed in user provided content and fixes up issues with
  # unbalanced tags and whatnot.
  #
  # See the Sanitize docs for more information on the underlying library:
  #
  # https://github.com/rgrove/sanitize/#readme
  class SanitizationFilter < Filter
    # The main sanitization whitelist. Only these elements and attributes are
    # allowed through by default.
    WHITELIST = {
      :elements => %w(
        h1 h2 h3 h4 h5 h6 h7 h8 br b i strong em a pre code img tt
        ins del sup sub p ol ul table th tr td blockquote dl dt dd
      ),
      :attributes => {
        'a'   => ['href'],
        'img' => ['src'],
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
                  'vspace', 'width']
      },
      :protocols => {
        'a'   => {'href' => ['http', 'https', 'mailto', :relative]},
        'img' => {'src'  => ['http', 'https', :relative]}
      },
      :transformers => [
        # whitelist only <li> elements that are descended from a <ul> or <ol>.
        # top-level <li> elements are removed because they can break out of
        # containing markup.
        lambda { |env|
          name, node = env[:node_name], env[:node]
          if name == 'li' && node.ancestors.any?{ |n| %w[ul ol].include?(n.name) }
            {:whitelist => true}
          end
        }
      ]
    }

    # A more limited sanitization whitelist. This includes all attributes,
    # protocols, and transformers from WHITELIST but with a more locked down
    # set of allowed elements.
    LIMITED = WHITELIST.merge(
      :elements => %w(b i strong em a pre code img ins del sup sub p ol ul li))

    # Sanitize markup using the Sanitize library.
    def perform
      Sanitize.clean_node!(doc, whitelist)
    end

    # The whitelist to use when sanitizing. This can be passed in the context
    # hash to the filter but defaults to WHITELIST constant value above.
    def whitelist
      context[:whitelist] || WHITELIST
    end
  end
end

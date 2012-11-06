require "nokogiri"
require "active_support/xml_mini/nokogiri" # convert Documents to hashes
require "escape_utils"

module HTML
  # GitHub HTML processing filters and utilities. This module includes a small
  # framework for defining DOM based content filters and applying them to user
  # provided content.
  #
  # See HTML::Pipeline::Filter for information on building filters.
  module Pipeline
    extend self

    autoload :VERSION,               'html/pipeline/version'
    autoload :Pipeline,              'html/pipeline/pipeline'
    autoload :Filter,                'html/pipeline/filter'
    autoload :BodyContent,           'html/pipeline/body_content'
    autoload :AutolinkFilter,        'html/pipeline/autolink_filter'
    autoload :CamoFilter,            'html/pipeline/camo_filter'
    autoload :EmailReplyFilter,      'html/pipeline/email_reply_filter'
    autoload :EmojiFilter,           'html/pipeline/emoji_filter'
    autoload :HttpsFilter,           'html/pipeline/https_filter'
    autoload :ImageMaxWidthFilter,   'html/pipeline/image_max_width_filter'
    autoload :MarkdownFilter,        'html/pipeline/markdown_filter'
    autoload :MentionFilter,         'html/pipeline/@mention_filter'
    autoload :PlainTextInputFilter,  'html/pipeline/plain_text_input_filter'
    autoload :SanitizationFilter,    'html/pipeline/sanitization_filter'
    autoload :SyntaxHighlightFilter, 'html/pipeline/syntax_highlight_filter'
    autoload :TextileFilter,         'html/pipeline/textile_filter'
    autoload :TableOfContentsFilter, 'html/pipeline/toc_filter'
    autoload :TextFilter,            'html/pipeline/text_filter'

    # Our DOM implementation.
    DocumentFragment = Nokogiri::HTML::DocumentFragment

    # Parse a String into a DocumentFragment object. When a DocumentFragment is
    # provided, return it verbatim.
    def parse(document_or_html)
      document_or_html ||= ''
      if document_or_html.is_a?(String)
        DocumentFragment.parse(document_or_html)
      else
        document_or_html
      end
    end

    # Helper method for building a HTML::Pipeline::Pipeline
    def build(filters, default_context = {}, result_class = nil)
      Pipeline.new(filters, default_context, result_class)
    end
  end
end

# XXX nokogiri monkey patches
class Nokogiri::XML::Node
  # Work around an issue with utf-8 encoded data being erroneously converted to
  # ... some other shit when replacing text nodes. See 'utf-8 output 2' in
  # user_content_test.rb for details.
  def replace_with_encoding_fix(replacement)
    if replacement.respond_to?(:to_str)
      replacement = document.fragment("<div>#{replacement}</div>").children.first.children
    end
    replace_without_encoding_fix(replacement)
  end

  alias_method :replace_without_encoding_fix, :replace
  alias_method :replace, :replace_with_encoding_fix

  def swap(replacement)
    replace(replacement)
    self
  end
end

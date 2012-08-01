require "nokogiri"

module GitHub
  # GitHub HTML processing filters and utilities. This module includes a small
  # framework for defining DOM based content filters and applying them to user
  # provided content.
  #
  # See GitHub::HTML::Filter for information on building filters.
  module HTML
    extend self

    autoload :Version,               'github/html/version'
    autoload :Pipeline,              'github/html/pipeline'
    autoload :Filter,                'github/html/filter'
    autoload :BodyContent,           'github/html/body_content'
    autoload :AutolinkFilter,        'github/html/autolink_filter'
    autoload :CamoFilter,            'github/html/camo_filter'
    autoload :CommitMentionFilter,   'github/html/commit_mention_filter'
    autoload :EmailReplyFilter,      'github/html/email_reply_filter'
    autoload :EmojiFilter,           'github/html/emoji_filter'
    autoload :HttpsFilter,           'github/html/https_filter'
    autoload :ImageMaxWidthFilter,   'github/html/image_max_width_filter'
    autoload :IssueMentionFilter,    'github/html/issue_mention_filter'
    autoload :MarkdownFilter,        'github/html/markdown_filter'
    autoload :MentionFilter,         'github/html/@mention_filter'
    autoload :TeamMentionFilter,     'github/html/team_mention_filter'
    autoload :PlainTextInputFilter,  'github/html/plain_text_input_filter'
    autoload :SanitizationFilter,    'github/html/sanitization_filter'
    autoload :SyntaxHighlightFilter, 'github/html/syntax_highlight_filter'
    autoload :TextileFilter,         'github/html/textile_filter'
    autoload :TableOfContentsFilter, 'github/html/toc_filter'

    # Our DOM implementation.
    DocumentFragment = Nokogiri::HTML::DocumentFragment

    # Parse a String into a DocumentFragment object. When a DocumentFragment is
    # provided, return it verbatim.
    def self.parse(document_or_html)
      document_or_html ||= ''
      if document_or_html.is_a?(String)
        DocumentFragment.parse(document_or_html)
      else
        document_or_html
      end
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

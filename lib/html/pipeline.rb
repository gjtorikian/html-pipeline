require "nokogiri"
require "active_support/xml_mini/nokogiri" # convert Documents to hashes
require "escape_utils"

module HTML
  # GitHub HTML processing filters and utilities. This module includes a small
  # framework for defining DOM based content filters and applying them to user
  # provided content.
  #
  # See HTML::Pipeline::Filter for information on building filters.
  #
  # Construct a Pipeline for running multiple HTML filters.  A pipeline is created once
  # with one to many filters, and it then can be `call`ed many times over the course
  # of its lifetime with input.
  #
  # filters         - Array of Filter objects. Each must respond to call(doc,
  #                   context) and return the modified DocumentFragment or a
  #                   String containing HTML markup. Filters are performed in the
  #                   order provided.
  # default_context - The default context hash. Values specified here will be merged
  #                   into values from the each individual pipeline run.  Can NOT be
  #                   nil.  Default: empty Hash.
  # result_class    - The default Class of the result object for individual
  #                   calls.  Default: Hash.  Protip:  Pass in a Struct to get
  #                   some semblance of type safety.
  class Pipeline
    autoload :VERSION,               'html/pipeline/version'
    autoload :Pipeline,              'html/pipeline/pipeline'
    autoload :Filter,                'html/pipeline/filter'
    autoload :AbsoluteSourceFilter,  'html/pipeline/absolute_source_filter'
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
    def self.parse(document_or_html)
      document_or_html ||= ''
      if document_or_html.is_a?(String)
        DocumentFragment.parse(document_or_html)
      else
        document_or_html
      end
    end

    # Public: Returns an Array of Filter objects for this Pipeline.
    attr_reader :filters

    def initialize(filters, default_context = {}, result_class = nil)
      raise ArgumentError, "default_context cannot be nil" if default_context.nil?
      @filters = filters.flatten.freeze
      @default_context = default_context.freeze
      @result_class = result_class || Hash
    end

    # Apply all filters in the pipeline to the given HTML.
    #
    # html    - A String containing HTML or a DocumentFragment object.
    # context - The context hash passed to each filter. See the Filter docs
    #           for more info on possible values. This object MUST NOT be modified
    #           in place by filters.  Use the Result for passing state back.
    # result  - The result Hash passed to each filter for modification.  This
    #           is where Filters store extracted information from the content.
    #
    # Returns the result Hash after being filtered by this Pipeline.  Contains an
    # :output key with the DocumentFragment or String HTML markup based on the
    # output of the last filter in the pipeline.
    def call(html, context = {}, result = nil)
      context = @default_context.merge(context)
      context = context.freeze
      result ||= @result_class.new
      result[:output] = @filters.inject(html) { |doc, filter| filter.call(doc, context, result) }
      result
    end

    # Like call but guarantee the value returned is a DocumentFragment.
    # Pipelines may return a DocumentFragment or a String. Callers that need a
    # DocumentFragment should use this method.
    def to_document(input, context = {}, result = nil)
      result = call(input, context, result)
      HTML::Pipeline.parse(result[:output])
    end

    # Like call but guarantee the value returned is a string of HTML markup.
    def to_html(input, context = {}, result = nil)
      result = call(input, context, result = nil)
      output = result[:output]
      if output.respond_to?(:to_html)
        output.to_html
      else
        output.to_s
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

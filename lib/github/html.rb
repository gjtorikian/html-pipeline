require 'nokogiri'

module GitHub
  # GitHub HTML processing filters and utilities. This module includes a small
  # framework for defining DOM based content filters and applying them to user
  # provided content.
  #
  # See GitHub::HTML::Filter for information on building filters.
  module HTML
    # Our DOM implementation.
    DocumentFragment = Nokogiri::HTML::DocumentFragment

    # Filter implementations
    require 'github/html/filter'
    require 'github/html/markdown_filter'
    require 'github/html/textile_filter'
    require 'github/html/email_reply_filter'
    require 'github/html/camo_filter'
    require 'github/html/sanitization_filter'
    require 'github/html/@mention_filter'
    require 'github/html/issue_mention_filter'
    require 'github/html/commit_mention_filter'
    require 'github/html/emoji_filter'

    # Contruct a pipeline for running multiple HTML filters.
    #
    # filters - Array of Filter objects. Each must respond to call(doc, context)
    #           and return the modified DocumentFragment. Filters are performed
    #           in the order provided.
    # context - The default context hash. Values specified here may be
    #           overridden by individual pipeline runs.
    class Pipeline
      def initialize(filters, context={})
        @filters = filters.flatten
        @context = context
      end

      # Apply all filters in the pipeline to the given HTML.
      #
      # html    - A String containing HTML or a DocumentFragment object.
      # context - The context hash passed to each filter. See the Filter docs
      #           for more info on possible values. This object may be modified
      #           in place by filters to make extracted information available
      #           to the caller.
      #
      # Returns a DocumentFragment.
      def call(html, context={})
        @context.each { |k, v| context[k] = v if !context.key?(k) }
        @filters.inject(html) { |doc, filter| filter.call(doc, context) }
      end
    end

    # Pipeline providing sanitization and image hijacking but no mention
    # related features.
    SimplePipeline = Pipeline.new [
      SanitizationFilter,
      CamoFilter
    ]

    # Pipeline used for most types of user provided content like comments
    # and issue bodies. Performs sanitization, image hijacking, and various
    # mention links.
    GFMPipeline = Pipeline.new [
      MarkdownFilter,
      SanitizationFilter,
      CamoFilter,
      MentionFilter,
      IssueMentionFilter,
      CommitMentionFilter,
      EmojiFilter
    ]

    # Pipeline used for email replies.
    EmailPipeline = Pipeline.new [
      EmailReplyFilter,
      MentionFilter,
      IssueMentionFilter,
      CommitMentionFilter
    ]

    # Pipeline used for really old comments and maybe other textile content
    # I guess.
    TextilePipeline = Pipeline.new [
      TextileFilter,
      SanitizationFilter
    ], :whitelist => SanitizationFilter::LIMITED

    extend self
  end
end

# XXX
#
# Work around an issue with Nokogiri::XML::Node#swap and #replace not
# working on text nodes when the replacement is a document fragment. See
# #407 in the Nokogiri issue tracker for more info:
#
# https://github.com/tenderlove/nokogiri/issues/407
#
# This monkey patch should be removed when a new version of Nokogiri
# is available.
class Nokogiri::XML::Text < Nokogiri::XML::CharacterData
  def replace(replacement)
    temp = add_next_sibling("<span></span>")
    remove
    temp.first.replace(replacement)
  end

  def swap(replacement)
    replace(replacement)
    self
  end
end

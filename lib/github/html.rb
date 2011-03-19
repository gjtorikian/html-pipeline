require 'nokogiri'

module GitHub
  # GitHub HTML processing filters and utilities. This module includes a small
  # framework for defining DOM based content filters and applying them to user
  # provided content.
  #
  # See GitHub::HTML::Filter for information on building filters.
  module HTML
    require 'github/html/filter'
    require 'github/html/camo_filter'
    require 'github/html/sanitization_filter'
    require 'github/html/@mention_filter'
    require 'github/html/issue_mention_filter'
    require 'github/html/commit_mention_filter'
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

require 'nokogiri'

module GitHub
  # Nokogiri HTML filters for user content provided in comments, issue bodies,
  # etc.
  module HTML
    require 'github/html/camouflage'
    require 'github/html/sanitization'
    require 'github/html/@mentions'
    require 'github/html/repository_mentions'
  end
end

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

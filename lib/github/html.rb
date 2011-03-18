require 'nokogiri'

module GitHub
  # Nokogiri HTML filters for user content provided in comments, issue bodies,
  # etc.
  module HTML
    require 'github/html/camouflage'
    require 'github/html/sanitization'
  end
end

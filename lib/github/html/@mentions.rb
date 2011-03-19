module GitHub::HTML

  module Mentions
    include GitHub::Mentionable

    # DOM filter that replaces @mentions with links in place on the given
    # Nokogiri document fragement. Mentions within <pre>, <code>, and <a>
    # elements are ignored.
    #
    # doc      - The Nokogiri document fragment to process, or a String.
    # base_url - The URL prefix for user links.
    #
    # Returns the same document node passed in doc but with new nodes added for
    # mention links. When doc was given as a string, a new
    # Nokogiri::HTML::DocumentFragment is returned instead.
    def user_mentions_filter(doc, base_url=GitHub::SSLHost)
      return nil if doc.nil?
      doc = Nokogiri::HTML::DocumentFragment.parse(doc) if doc.is_a?(String)
      doc.search('text()').each do |node|
        next if !node.content.include?('@')
        next if node.ancestors('pre, code, a').any?
        html = mention_link_filter(node.content, base_url)
        node.replace(html) if html != node.content
      end
      doc
    end

    extend self
  end
end

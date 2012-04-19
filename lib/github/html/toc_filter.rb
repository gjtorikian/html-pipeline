module GitHub::HTML
  # HTML filter that adds a 'name' attribute to all headers
  # in a document, so they can be accessed from a table of contents
  #
  # TODO: besides adding the name attribute, we should get around to
  # eventually generating the Table of Contents itself, with links
  # to each header
  class TableOfContentsFilter < Filter
    def call
      headers = Hash.new(0)
      doc.css('h1, h2, h3, h4, h5, h6').each do |node|
        name = node.text.downcase
        name.gsub!(/[^\w\- ]/, '') # remove punctuation
        name.gsub!(' ', '-') # replace spaces with dash
        name = EscapeUtils.escape_uri(name) # escape extended UTF-8 chars

        uniq = (headers[name] > 0) ? "-#{headers[name]}" : ''
        headers[name] += 1

        node.before "<a name=\"#{name}#{uniq}\"></a>"
      end
      doc
    end
  end
end

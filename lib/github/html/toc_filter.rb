
          header_content.add_previous_sibling(%Q{<a name="#{name}#{uniq}" class="anchor" href="##{name}#{uniq}"><span class="mini-icon-link"></span></a>})
        end
        headers[name] += 1
        if header_content = node.children.first
        name = EscapeUtils.escape_uri(name) # escape extended UTF-8 chars
        name = node.text.downcase
        name.gsub!(' ', '-') # replace spaces with dash
        name.gsub!(/[^\w\- ]/, '') # remove punctuation
        uniq = (headers[name] > 0) ? "-#{headers[name]}" : ''
      doc
      doc.css('h1, h2, h3, h4, h5, h6').each do |node|
      end
      headers = Hash.new(0)
    def call
    end
  #
  # eventually generating the Table of Contents itself, with links
  # HTML filter that adds a 'name' attribute to all headers
  # in a document, so they can be accessed from a table of contents
  # to each header
  # TODO: besides adding the name attribute, we should get around to
  class TableOfContentsFilter < Filter
  end
end
module GitHub::HTML
module HTML
  class Pipeline
    # HTML filter that adds a 'name' attribute to all headers
    # in a document, so they can be accessed from a table of contents.
    #
    # Generates the Table of Contents, with links to each header.
    #
    # Examples
    #
    #  TocPipeline =
    #    HTML::Pipeline.new [
    #      HTML::Pipeline::TableOfContentsFilter
    #    ]
    #  # => #<HTML::Pipeline:0x007fc13c4528d8...>
    #  orig = %(<h1>Ice cube</h1><p>is not for the pop chart</p>)
    #  # => "<h1>Ice cube</h1><p>is not for the pop chart</p>"
    #  result = {}
    #  # => {}
    #  TocPipeline.call(orig, {}, result)
    #  # => {:toc=> ...}
    #  result[:toc]
    #  # => "<ul class=\"section-nav\">\n<li><a href=\"#ice-cube\">...</li><ul>"
    #  result[:output].to_s
    #  # => "<h1>\n<a name=\"ice-cube\" class=\"anchor\" href=\"#ice-cube\">..."
    class TableOfContentsFilter < Filter
      PUNCTUATION_REGEXP = RUBY_VERSION > "1.9" ? /[^\p{Word}\- ]/u : /[^\w\- ]/

      def call
        result[:toc] = ""

        headers = Hash.new(0)
        doc.css('h1, h2, h3, h4, h5, h6').each do |node|
          text = node.text
          name = text.downcase
          name.gsub!(PUNCTUATION_REGEXP, '') # remove punctuation
          name.gsub!(' ', '-') # replace spaces with dash

          uniq = (headers[name] > 0) ? "-#{headers[name]}" : ''
          headers[name] += 1
          if header_content = node.children.first
            result[:toc] << %Q{<li><a href="##{name}#{uniq}">#{text}</a></li>\n}
            header_content.add_previous_sibling(%Q{<a name="#{name}#{uniq}" class="anchor" href="##{name}#{uniq}"><span class="octicon octicon-link"></span></a>})
          end
        end
        result[:toc] = %Q{<ul class="section-nav">\n#{result[:toc]}</ul>} unless result[:toc].empty?
        doc
      end
    end
  end
end

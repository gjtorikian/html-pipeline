require 'github/linguist'

module GitHub::HTML
  # HTML Filter that syntax highlights code blocks wrapped
  # in <pre lang="...">.
  class SyntaxHighlightFilter < Filter
    def call
      doc.search('pre').each do |node|
        next unless lang = node['lang']
        next unless lexer = Pygments::Lexer[lang]
        text = node.inner_text
        html = lexer.highlight(text)
        node.replace(html)
      end
      doc
    end
  end
end

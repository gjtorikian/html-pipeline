require 'github/albino'

module GitHub::HTML
  # HTML Filter that syntax highlights code blocks wrapped
  # in <pre lang="...">.
  class SyntaxHighlightFilter < Filter
    def call
      doc.search('pre').each do |node|
        next unless lang = node['lang']
        text = node.inner_text
        html = GitHub::Albino.safe_colorize(text, lang)
        node.replace(html)
      end
    end
  end
end

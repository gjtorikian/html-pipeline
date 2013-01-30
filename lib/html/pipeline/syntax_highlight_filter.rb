begin
  require 'linguist'
rescue LoadError
  $stderr.puts "You need to install linguist before using the SyntaxHighlightFilter. See README.md for details"
  exit 1
end

module HTML
  class Pipeline
    # HTML Filter that syntax highlights code blocks wrapped
    # in <pre lang="...">.
    class SyntaxHighlightFilter < Filter
      def call
        doc.search('pre').each do |node|
          next unless lang = node['lang']
          next unless lexer = Pygments::Lexer[lang]
          text = node.inner_text

          html = highlight_with_timeout_handling(lexer, text)
          next if html.nil?

          node.replace(html)
        end
        doc
      end

      def highlight_with_timeout_handling(lexer, text)
        lexer.highlight(text)
      rescue Timeout::Error => boom
        nil
      end
    end
  end
end
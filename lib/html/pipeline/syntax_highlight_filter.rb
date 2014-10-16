begin
  require "linguist"
rescue LoadError => e
  if e.message =~ /linguist$/
    abort "Missing dependency 'github-linguist' for SyntaxHighlightFilter. See README.md for details."
  else
    raise
  end
end

module HTML
  class Pipeline
    # HTML Filter that syntax highlights code blocks wrapped
    # in <pre lang="...">.
    class SyntaxHighlightFilter < Filter
      def call
        doc.search('pre').each do |node|
          default = context[:highlight] && context[:highlight].to_s
          next unless lang = node['lang'] || default
          next unless lexer = Pygments::Lexer[lang]
          text = node.inner_text

          html = highlight_with_timeout_handling(lexer, text)
          next if html.nil?

          if (node = node.replace(html).first)
            klass = node["class"]
            klass = [klass, "highlight-#{lang}"].compact.join " "

            node["class"] = klass
          end
        end
        doc
      end

      def highlight_with_timeout_handling(lexer, text)
        lexer.highlight(text)
      rescue Timeout::Error
        nil
      end
    end
  end
end

require 'linguist'

module HTML
  class Pipeline
    # HTML Filter that syntax highlights code blocks wrapped in <pre> tags.
    #
    # If a <pre> has a "lang" attribute, it is taken as the language
    # identifier. Otherwise, the language is auto-detected from the contents of
    # the code block. Pass in `:detect_syntax => false` to disable this.
    # You can also disable language detection per code block by assigning a
    # value to the "lang" attribute such as "plain".
    #
    # Language detection is done with GitHub Linguist. Note that some popular
    # languages that Linguist 2.3.4 isn't yet taught to detect are:
    # ActionScript, C#, Common Lisp, CSS, Erlang, Haskell, HTML, Lua, SQL.
    class SyntaxHighlightFilter < Filter
      def call
        doc.search('pre').each do |pre|
          code = pre.inner_text

          if language_name = language_name_from_node(pre)
            language = lookup_language(language_name)
          elsif detect_language?
            detected = detect_languages(code).first
            language = detected && lookup_language(detected[0])
          end

          if html = language && colorize(language, code)
            pre.replace(html)
          end
        end
        doc
      end

      def detect_language?
        context[:detect_syntax] != false
      end

      def language_name_from_node node
        node['lang']
      end

      def lookup_language name
        Linguist::Language[name]
      end

      def detect_languages code
        Linguist::Classifier.classify(classifier_db, code, possible_languages)
      end

      def classifier_db() Linguist::Samples::DATA end

      def possible_languages
        popular_language_names & sampled_languages
      end

      def popular_language_names
        Linguist::Language.popular.map {|lang| lang.name }
      end

      def sampled_languages
        classifier_db['languages'].keys
      end

      def colorize language, code
        language.colorize code
      rescue Timeout::Error => boom
        nil
      end
    end
  end
end

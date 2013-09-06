require 'safe_yaml'

module HTML
  class Pipeline
    # Filter that represents YAML front matter as HTML
    class YamlFilter < TextFilter
      def call
        begin
          # definition of a YAML header
          if text =~ /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m
            content = $POSTMATCH
            data = YAML.safe_load($1)
            puts data
          else
            return text
          end
        rescue SyntaxError => e
          puts "YAML Exception reading #{text}: #{e.message}"
        end

        text
      end
    end
  end
end

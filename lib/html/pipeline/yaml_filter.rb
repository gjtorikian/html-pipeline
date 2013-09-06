require 'safe_yaml'

module HTML
  class Pipeline
    # Filter that represents YAML front matter as HTML
    class YamlFilter < TextFilter
      def call
        begin
          # definition of a YAML header
          if text =~ /\A(---\s*\n.*?\n?)^(---\s*$\n?)(.*)/m
            content = $3
            data = YAML.safe_load($1)
            text = process_yaml(data) << "\n\n" << content
          end
        rescue SyntaxError => e
          puts "YAML Exception reading #{text}: #{e.message}"
        end

        text
      end

      def process_yaml(data)
        html = "<table>"
        data.each do |key, value|
          html << "<tr>"
          html << "<td>#{key}</td><td>#{value}</td>"
          html << "</tr>"
        end
        html << "</table>"
      end
    end

  end
end

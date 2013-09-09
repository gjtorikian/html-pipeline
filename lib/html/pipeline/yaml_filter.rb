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
        th_row = ''
        tb_row = ''
        tr_row = ''

        if !data.keys.empty?
          data.keys.each do |header|
            th_row << table_format("TH", header)
          end

          th = table_format("THEAD", table_format("TR", th_row))

          if !data.keys.empty?
            data.values.each do |value|
              if value.is_a?(Hash)
                tb_row << table_format("TD", process_yaml(value))
              else
                tb_row << table_format("TD", value)
              end

              tr_row << table_format("TR", tb_row)
              tb_row = ""
            end
          end

          tb = table_format("TB", tr_row)

          table_format("TBL", th, tb)
        else
          ""
        end
      end


      def table_format(str, *values)
        # patterns for table elements
        case str
        when "TBL"
          "<table>#{values[0]}#{values[1]}</table>"
        when "THEAD"
          "\n  <thead>#{values[0]}</thead>"
        when "TB"
          "\n  <tbody>#{values[0]}</tbody>\n"
        when "TR"
          "\n  <tr>#{values[0]}</tr>\n  "
        when "TH"
          "\n  <th>#{values[0]}</th>\n  "
        when "TD"
          "\n  <td>#{values[0]}</td>\n  "
        end
      end
    end
  end
end

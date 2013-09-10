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
            # the point of the sub is to add an id to the first table element
            text = process_yaml(data).sub(/<table/, "<table id=\"metadata\"") << "\n\n" << content
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

        is_array = data.is_a?(Array)
        is_hash_array = is_array && data.any? { |d| d.is_a?(Hash) }

        if is_hash_array
          data[0].keys.each do |header|
            th_row << table_format("TH", header)
          end
        elsif !data.is_a?(Array)
          data.keys.each do |header|
            th_row << table_format("TH", header)
          end
        end

        th = table_format("THEAD", table_format("TR", th_row)) unless th_row.empty?

        values = is_array ? data : data.values

        values.each do |value|
          if value.is_a?(Array)
            tb_row << table_format("TD", process_yaml(value))
          elsif value.is_a?(Hash)
            value.values.each do |nested_value|
              tb_row << table_format("TD", nested_value)
            end
            tr_row << table_format("TR", tb_row)
            tb_row = ""
          else
            tb_row << table_format("TD", value)
          end
        end

        tr_row << table_format("TR", tb_row) unless tb_row.empty?
        tb = table_format("TB", tr_row)

        table_format("TBL", th, tb)
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

module GitHub::HTML
  module PlainTextFilter
    def self.call(body)
      Pipeline.call(body)
    end

    class Filter < ::GitHub::HTML::Filter
      def call
        links = []

        doc.search("a").each do |node|
          links << File.join(GitHub::SSLHost, node["href"])

          index = links.size
          label = "#{node.text} [#{index}]"

          node.replace(Nokogiri::XML::Text.new(label, doc))
        end

        if links.any?
          doc.add_child(Nokogiri::XML::Text.new("\n\n", doc))
        end

        links.each_with_index do |link, i|
          text = "[#{i + 1}]: #{link}\n"
          doc.add_child(Nokogiri::XML::Text.new(text, doc))
        end
      end
    end

    Pipeline = ::GitHub::HTML::Pipeline.new [
      lambda { |doc, _| "<p>#{doc}</p>" },
      ::GitHub::HTML::IssueMentionFilter,
      ::GitHub::HTML::CommitMentionFilter,
      Filter,
      lambda { |doc, _| doc.text }
    ]
  end
end

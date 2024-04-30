# frozen_string_literal: true

require "test_helper"
require "html_pipeline/node_filter/table_of_contents_filter"

class HTMLPipeline
  class NodeFilter
    class TableOfContentsFilterTest < Minitest::Test
      TocFilter = HTMLPipeline::NodeFilter::TableOfContentsFilter

      TocPipeline =
        HTMLPipeline.new(convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new, node_filters: [
          TocFilter.new,
        ])

      def toc_s(content)
        result = TocPipeline.call(content, context: {}, result: result)
        result[:toc].to_s
      end

      def test_anchors_and_list_are_added_properly
        orig = %(# Ice cube\n\nWill swarm on any motherfucker in a blue uniform)
        result = TocPipeline.call(orig)

        assert_includes(result[:output], "<a href=")
      end

      def test_custom_anchor_html_added_properly
        orig = %(# Ice cube)
        expected = %(<h1><a href="#ice-cube" aria-hidden="true" id="ice-cube" class="anchor">#</a>Ice cube</h1>)
        pipeline = HTMLPipeline.new(convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new, node_filters: [
          TocFilter.new(context: { anchor_html: "#" }),
        ])
        result = pipeline.call(orig)

        assert_equal(expected, result[:output])
      end

      def test_toc_list_added_properly
        orig = %(# Ice cube\n\nWill swarm on any motherfucker in a blue uniform)
        result = TocPipeline.call(orig)

        assert_equal({ href: "#ice-cube", text: "Ice cube" }, result[:toc].first)
      end

      def test_anchors_have_sane_names
        orig = %(# Dr. Dre\n\n# Ice Cube\n\n# Eazy-E\n\n# MC Ren)

        result = TocPipeline.call(orig)[:output]

        assert_includes(result, '"dr-dre"')
        assert_includes(result, '"ice-cube"')
        assert_includes(result, '"eazy-e"')
        assert_includes(result, '"mc-ren"')
      end

      def test_anchors_have_aria_hidden
        orig = "# Straight Outta Compton"
        result = TocPipeline.call(orig)[:output]

        assert_includes(result, 'aria-hidden="true"')
      end

      def test_toc_hrefs_have_sane_values
        orig = %(# Dr. Dre\n\n# Ice Cube\n\n# Eazy-E\n\n# MC Ren)
        result = TocPipeline.call(orig)[:output]

        assert_includes(result, '"#dr-dre"')
        assert_includes(result, '"#ice-cube"')
        assert_includes(result, '"#eazy-e"')
        assert_includes(result, '"#mc-ren"')
      end

      def test_dupe_headers_have_unique_trailing_identifiers
        orig = <<~STR
          # Straight Outta Compton

          ## Dopeman

          ### Express Yourself

          # Dopeman
        STR

        result = TocPipeline.call(orig)[:output]

        assert_includes(result, '"dopeman"')
        assert_includes(result, '"dopeman-1"')
      end

      def test_dupe_headers_have_unique_toc_anchors
        orig = <<~STR
          # Straight Outta Compton

          ## Dopeman

          ### Express Yourself

          # Dopeman
        STR

        assert_includes(toc_s(orig), '"#dopeman"')
        assert_includes(toc_s(orig), '"#dopeman-1"')
      end

      def test_all_header_tags_are_found_when_adding_anchors
        orig = <<~STR
          # "Funky President" by James Brown
          ## "It's My Thing" by Marva Whitney
          ### "Boogie Back" by Roy Ayers
          #### "Feel Good" by Fancy
          ##### "Funky Drummer" by James Brown
          ###### "Ruthless Villain" by Eazy-E
        STR

        result = TocPipeline.call(orig, context: {}, result: result)

        doc = Nokogiri::HTML(result[:output])

        assert_equal(6, doc.search("a").size)
      end

      def test_toc_outputs_escaped_html
        orig = %(# &lt;img src="x" onerror="alert(42)"&gt;)

        refute_includes(toc_s(orig), %(<img src="x" onerror="alert(42)">))
      end

      def test_toc_is_complete
        orig = <<~STR
          # "Funky President" by James Brown
          ## "It's My Thing" by Marva Whitney
          ### "Boogie Back" by Roy Ayers
          #### "Feel Good" by Fancy
          ##### "Funky Drummer" by James Brown
          ###### "Ruthless Villain" by Eazy-E
        STR

        result = TocPipeline.call(orig)[:toc]
        expected = [
          { href: "#funky-president-by-james-brown", text: "&quot;Funky President&quot; by James Brown" },
          { href: "#its-my-thing-by-marva-whitney", text: "&quot;It's My Thing&quot; by Marva Whitney" },
          { href: "#boogie-back-by-roy-ayers", text: "&quot;Boogie Back&quot; by Roy Ayers" },
          { href: "#feel-good-by-fancy", text: "&quot;Feel Good&quot; by Fancy" },
          { href: "#funky-drummer-by-james-brown", text: "&quot;Funky Drummer&quot; by James Brown" },
          { href: "#ruthless-villain-by-eazy-e", text: "&quot;Ruthless Villain&quot; by Eazy-E" },
        ]

        0..6.times do |i|
             assert_equal(expected[i], result[i])
           end
      end

      def test_anchors_with_utf8_characters
        orig = <<~STR
          # 日本語

          # Русский
        STR

        rendered_h1s = Nokogiri::HTML(TocPipeline.call(orig)[:output]).search("h1").map(&:to_s)

        assert_equal(
          "<h1>\n<a href=\"#%E6%97%A5%E6%9C%AC%E8%AA%9E\" aria-hidden=\"true\" id=\"%E6%97%A5%E6%9C%AC%E8%AA%9E\" class=\"anchor\"><span aria-hidden=\"true\" class=\"anchor\"></span></a>日本語</h1>",
          rendered_h1s[0],
        )
        assert_equal(
          "<h1>\n<a href=\"#%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9\" aria-hidden=\"true\" id=\"%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9\" class=\"anchor\"><span aria-hidden=\"true\" class=\"anchor\"></span></a>Русский</h1>",
          rendered_h1s[1],
        )
      end

      def test_toc_with_utf8_characters
        orig = <<~STR
          # 日本語

          # Русский
        STR

        result = TocPipeline.call(orig)[:toc]

        expected = [
          {
            href: "#%E6%97%A5%E6%9C%AC%E8%AA%9E",
            text: "日本語",
          },
          {
            href: "#%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9",
            text: "Русский",
          },
        ]

        0..2.times do |i|
          assert_equal(expected[i], result[i])
        end
      end
    end
  end
end

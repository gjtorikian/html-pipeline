require 'asciidoctor'
# only require tilt if using custom standalone ERB template
#require 'tilt'

module HTML
  class Pipeline
    # HTML Filter that converts AsciiDoc text into HTML.
    #
    # This filter is different from most in that it can take a non-HTML as
    # input. It must be used as the first filter in a pipeline.
    #
    # This filter does not write any additional information to the context hash.
    #
    # Examples
    #
    #   input = <<EOS
    #   = Sample Document
    #   Author Name
    #   
    #   Preamble paragraph.
    #   
    #   == Sample Section
    #   
    #   Section content.
    #   
    #   .GitHub usernames
    #   - @jch
    #   - @jm
    #   - @mojavelinux
    #   
    #   [source,ruby]
    #   require 'asciidoctor'
    #   puts Asciidoctor.render('http://asciidoctor.org[Asciidoctor]')
    #   
    #   :shipit: 
    #  EOS
    #
    #  filters = [
    #    HTML::Pipeline::AsciiDocFilter,
    #    HTML::Pipeline::SanitizationFilter,
    #    HTML::Pipeline::ImageMaxWidthFilter,
    #    HTML::Pipeline::EmojiFilter,
    #    HTML::Pipeline::MentionFilter,
    #    HTML::Pipeline::AutolinkFilter,
    #    HTML::Pipeline::TableOfContentsFilter,
    #    HTML::Pipeline::SyntaxHighlightFilter
    #  ]
    #
    #  puts HTML::Pipeline.new(filters, {}).call(input)[:output]
    #
    class AsciiDocFilter < TextFilter
      def initialize(text, context = nil, result = nil)
        super text, context, result
      end
    
      # Convert AsciiDoc to HTML using Asciidoctor
      def call
        html = Asciidoctor.render(@text, :attributes => 'notitle! idprefix idseparator=- github')
            # option for using standalone ERB template (instead of monkeypatched one below)
            #:template_dir => File.join(File.dirname(__FILE__), 'asciidoctor_templates')).strip
      end

    end
  end
end

require 'asciidoctor/backends/html5'

module Asciidoctor
  module HTML5
    # copied from Asciidoctor::HTML5::BlockAdmonitionTemplate, tweaked for GitHub
    # yes, this template is ugly, but it's (mostly) optimized for speed, not looks
    # templates should not be overridden this way generally, but rather by using Tilt-supported templates
    # since this is such a narrow change, we are monkeypatching to avoid a dependency on Tilt
    class BlockAdmonitionTemplate < BaseTemplate
      OCTICON_MAPPING = {
        'tip'       => 'star',
        'note'      => 'info',
        'warning'   => 'alert',
        'caution'   => 'megaphone',
        'important' => 'stop'
      }

      def template
        @template ||= @eruby.new <<-EOS
<%#encoding:UTF-8%><table>
<tr>
<td>
<i alt="mega-octicon octicon-<%= template.class::OCTICON_MAPPING[attr 'name'] %>"></i>
</td>
<td><%= title? ? %(
<div>\#{title}</div>) : nil %>
<%= content %>
</td>
</tr>
</table>
      EOS
      end
    end

    # copied from Asciidoctor::HTML5::BlockListingTemplate, tweaked for GitHub
    # yes, this template is ugly, but it's (mostly) optimized for speed, not looks
    # templates should not be overridden this way generally, but rather by using Tilt-supported templates
    # since this is such a narrow change, we are monkeypatching to avoid a dependency on Tilt
    class BlockListingTemplate < BaseTemplate
      def template
        @template ||= @eruby.new <<-EOS
<%#encoding:UTF-8%><%= title? ? %(
<div>\#{@caption}\#{title}</div>) : nil %><%
if attr? 'style', 'source', false %>
<pre lang="<%= (attr 'language') %>"><code><%= content %></code></pre><%
else %>
<pre><%= content %></pre><%
end %>
      EOS
      end
    end
  end
end

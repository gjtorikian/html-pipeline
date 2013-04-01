# HTML::Pipeline [![Build Status](https://secure.travis-ci.org/jch/html-pipeline.png)](http://travis-ci.org/jch/html-pipeline)

GitHub HTML processing filters and utilities. This module includes a small
framework for defining DOM based content filters and applying them to user
provided content. Read an introduction about this project in
[this blog post](https://github.com/blog/1311-html-pipeline-chainable-content-filters).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'html-pipeline'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install html-pipeline
```

## Usage

This library provides a handful of chainable HTML filters to transform user
content into markup. A filter takes an HTML string or
`Nokogiri::HTML::DocumentFragment`, optionally manipulates it, and then
outputs the result.

For example, to transform Markdown source into Markdown HTML:

```ruby
require 'html/pipeline'

filter = HTML::Pipeline::MarkdownFilter.new("Hi **world**!")
filter.call
```

Filters can be combined into a pipeline which causes each filter to hand its
output to the next filter's input. So if you wanted to have content be
filtered through Markdown and be syntax highlighted, you can create the
following pipeline:

```ruby
pipeline = HTML::Pipeline.new [
  HTML::Pipeline::MarkdownFilter,
  HTML::Pipeline::SyntaxHighlightFilter
]
result = pipeline.call <<-CODE
This is *great*:

    some_code(:first)

CODE
result[:output].to_s
```

Prints:

```html
<p>This is <em>great</em>:</p>

<div class="highlight">
<pre><span class="n">some_code</span><span class="p">(</span><span class="ss">:first</span><span class="p">)</span>
</pre>
</div>
```

Some filters take an optional **context** and/or **result** hash. These are
used to pass around arguments and metadata between filters in a pipeline. For
example, if you want don't want to use GitHub formatted Markdown, you can
pass an option in the context hash:

```ruby
filter = HTML::Pipeline::MarkdownFilter.new("Hi **world**!", :gfm => false)
filter.call
```

## Filters

* `MentionFilter` - replace `@user` mentions with links
* `AbsoluteSourceFilter` - replace relative image urls with fully qualified versions
* `AutoLinkFilter` - auto_linking urls in HTML
* `CamoFilter` - replace http image urls with [camo-fied](https://github.com/atmos/camo) https versions
* `EmailReplyFilter` - util filter for working with emails
* `EmojiFilter` - everyone loves [emoji](http://www.emoji-cheat-sheet.com/)!
* `HttpsFilter` - HTML Filter for replacing http github urls with https versions.
* `ImageMaxWidthFilter` - link to full size image for large images
* `MarkdownFilter` - convert markdown to html
* `PlainTextInputFilter` - html escape text and wrap the result in a div
* `SanitizationFilter` - whitelist sanitize user markup
* `SyntaxHighlightFilter` - [code syntax highlighter](#syntax-highlighting)
* `TextileFilter` - convert textile to html
* `TableOfContentsFilter` - anchor headings with name attributes

## Syntax highlighting

`SyntaxHighlightFilter` uses [github-linguist](https://github.com/github/linguist)
to detect and highlight languages. It isn't included as a dependency by default
because it's a large dependency and
[a hassle to build on heroku](https://github.com/jch/html-pipeline/issues/33).
To use the filter, add the following to your Gemfile:

```ruby
gem 'github-linguist'
```

## Examples

We define different pipelines for different parts of our app. Here are a few
paraphrased snippets to get you started:

```ruby
# The context hash is how you pass options between different filters.
# See individual filter source for explanation of options.
context = {
  :asset_root => "http://your-domain.com/where/your/images/live/icons",
  :base_url   => "http://your-domain.com"
}

# Pipeline providing sanitization and image hijacking but no mention
# related features.
SimplePipeline = Pipeline.new [
  SanitizationFilter,
  TableOfContentsFilter, # add 'name' anchors to all headers
  CamoFilter,
  ImageMaxWidthFilter,
  SyntaxHighlightFilter,
  EmojiFilter,
  AutolinkFilter
], context

# Pipeline used for user provided content on the web
MarkdownPipeline = Pipeline.new [
  MarkdownFilter,
  SanitizationFilter,
  CamoFilter,
  ImageMaxWidthFilter,
  HttpsFilter,
  MentionFilter,
  EmojiFilter,
  SyntaxHighlightFilter
], context.merge(:gfm => true) # enable github formatted markdown


# Define a pipeline based on another pipeline's filters
NonGFMMarkdownPipeline = Pipeline.new(MarkdownPipeline.filters,
  context.merge(:gfm => false))

# Pipelines aren't limited to the web. You can use them for email
# processing also.
HtmlEmailPipeline = Pipeline.new [
  ImageMaxWidthFilter
], {}

# Just emoji.
EmojiPipeline = Pipeline.new [
  HTMLInputFilter,
  EmojiFilter
], context
```

## Extending
To write a custom filter, you need a class with a `call` method that inherits
from `HTML::Pipeline::Filter`.

For example this filter adds a base url to images that are root relative:

```ruby
require 'uri'

class RootRelativeFilter < HTML::Pipeline::Filter

  def call
    doc.search("img").each do |img|
      next if img['src'].nil?
      src = img['src'].strip
      if src.start_with? '/'
        img["src"] = URI.join(context[:base_url], src).to_s
      end
    end
    doc
  end

end
```

Now this filter can be used in a pipeline:

```ruby
Pipeline.new [ RootRelativeFilter ], { :base_url => 'http://somehost.com' }
```

## Instrumenting

Filters and Pipelines can be set up to be instrumented when called. The pipeline
must be setup with an [ActiveSupport::Notifications]
(http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html)
compatible service object and a name. New pipeline objects will default to the
`HTML::Pipeline.default_instrumentation_service` object.

``` ruby
# the AS::Notifications-compatible service object
service = ActiveSupport::Notifications

# instrument a specific pipeline
pipeline = HTML::Pipeline.new [MarkdownFilter], context
pipeline.setup_instrumentation "MarkdownPipeline", service

# or set default instrumentation service for all new pipelines
HTML::Pipeline.default_instrumentation_service = service
pipeline = HTML::Pipeline.new [MarkdownFilter], context
pipeline.setup_instrumentation "MarkdownPipeline"
```

Filters are instrumented when they are run through the pipeline. A
`call_filter.html_pipeline` event is published once the filter finishes. The
`payload` should include the `filter` name. Each filter will trigger its own
instrumentation call.

``` ruby
service.subscribe "call_filter.html_pipeline" do |event, start, ending, transaction_id, payload|
  payload[:pipeline] #=> "MarkdownPipeline", set with `setup_instrumentation`
  payload[:filter] #=> "MarkdownFilter"
  payload[:context] #=> context Hash
  payload[:result] #=> instance of result class
  payload[:result][:output] #=> output HTML String or Nokogiri::DocumentFragment
end
```

The full pipeline is also instrumented:

``` ruby
service.subscribe "call_pipeline.html_pipeline" do |event, start, ending, transaction_id, payload|
  payload[:pipeline] #=> "MarkdownPipeline", set with `setup_instrumentation`
  payload[:filters] #=> ["MarkdownFilter"]
  payload[:doc] #=> HTML String or Nokogiri::DocumentFragment
  payload[:context] #=> context Hash
  payload[:result] #=> instance of result class
  payload[:result][:output] #=> output HTML String or Nokogiri::DocumentFragment
end
```

## Documentation

Full reference documentation can be [found here](http://rubydoc.info/gems/html-pipeline/frames).

## Development

To see what has changed in recent versions, see the [CHANGELOG](https://github.com/jch/html-pipeline/blob/master/CHANGELOG.md).

```sh
bundle
rake test
```

## Contributing

1. [Fork it](https://help.github.com/articles/fork-a-repo)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](https://help.github.com/articles/using-pull-requests)

## Contributors

Thanks to all of [these contributors](https://github.com/jch/html-pipeline/graphs/contributors).

Project is a member of the [OSS Manifesto](http://ossmanifesto.org/).

# HTML-Pipeline

HTML processing filters and utilities. This module is a small
framework for defining CSS-based content filters and applying them to user
provided content.

[Although this project was started at GitHub](https://github.com/blog/1311-html-pipeline-chainable-content-filters), they no longer use it. This gem must be considered standalone and independent from GitHub.

- [HTML-Pipeline](#html-pipeline)
  - [Installation](#installation)
  - [Usage](#usage)
    - [More Examples](#more-examples)
  - [Filters](#filters)
    - [TextFilters](#textfilters)
    - [ConvertFilter](#convertfilter)
    - [Sanitization](#sanitization)
    - [NodeFilters](#nodefilters)
  - [Dependencies](#dependencies)
  - [Documentation](#documentation)
  - [Instrumenting](#instrumenting)
  - [Third Party Extensions](#third-party-extensions)
  - [FAQ](#faq)
    - [1. Why doesn't my pipeline work when there's no root element in the document?](#1-why-doesnt-my-pipeline-work-when-theres-no-root-element-in-the-document)
    - [2. How do I customize an allowlist for `SanitizationFilter`s?](#2-how-do-i-customize-an-allowlist-for-sanitizationfilters)
    - [Contributors](#contributors)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'html-pipeline'
```

And then execute:

```sh
$ bundle
```

Or install it by yourself as:

```sh
$ gem install html-pipeline
```

## Usage

This library provides a handful of chainable HTML filters to transform user
content into HTML markup. Each filter does some work, and then hands off the
results tothe next filter. A pipeline has several kinds of filters available to use:

- Multiple `TextFilter`s, which operate a UTF-8 string
- A `ConvertFilter` filter, which turns text into HTML (eg., Commonmark/Asciidoc -> HTML)
- A `SanitizationFilter`, which remove dangerous/unwanted HTML elements and attributes
- Multiple `NodeFilter`s, which operate on a UTF-8 HTML document

You can assemble each sequence into a single pipeline, or choose to call each filter individually.

As an example, suppose we want to transform Commonmark source text into Markdown HTML:

```
Hey there, @gjtorikian
```

With the content, we also want to:

- change every instance of `Hey` to `Hello`
- strip undesired HTML
- linkify @mention

We can construct a pipeline to do all that like this:

```ruby
require 'html_pipeline'

class HelloJohnnyFilter < HTMLPipelineFilter
  def call
    text.gsub("Hey", "Hello")
  end
end

pipeline = HTMLPipeline.new(
  text_filters: [HelloJohnnyFilter.new]
  convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new,
    # note: next line is not needed as sanitization occurs by default;
    # see below for more info
  sanitization_config: HTMLPipeline::SanitizationFilter::DEFAULT_CONFIG,
  node_filters: [HTMLPipeline::NodeFilter::MentionFilter.new]
)
pipeline.call(user_supplied_text) # recommended: can call pipeline over and over
```

Filters can be custom ones you create (like `HelloJohnnyFilter`), and `HTMLPipeline` additionally provides several helpful ones (detailed below). If you only need a single filter, you can call one individually, too:

```ruby
filter = HTMLPipeline::ConvertFilter::MarkdownFilter.new
filter.call(text)
```

Filters combine into a sequential pipeline, and each filter hands its
output to the next filter's input. Text filters are
processed first, then the convert filter, sanitization filter, and finally, the node filters.

Some filters take optional `context` and/or `result` hash(es). These are
used to pass around arguments and metadata between filters in a pipeline. For
example, if you want to disable footnotes in the `MarkdownFilter`, you can pass an option in the context hash:

```ruby
context = { markdown: { extensions: { footnotes: false } } }
filter = HTMLPipeline::ConvertFilter::MarkdownFilter.new(context: context)
filter.call("Hi **world**!")
```

Alternatively, you can construct a pipeline, and pass in a context during the call:

```ruby
pipeline = HTMLPipeline.new(
  convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new,
  node_filters: [HTMLPipeline::NodeFilter::MentionFilter.new]
)
pipeline.call(user_supplied_text, context: { markdown: { extensions: { footnotes: false } } })
```

Please refer to the documentation for each filter to understand what configuration options are available.

### More Examples

Different pipelines can be defined for different parts of an app. Here are a few
paraphrased snippets to get you started:

```ruby
# The context hash is how you pass options between different filters.
# See individual filter source for explanation of options.
context = {
  asset_root: "http://your-domain.com/where/your/images/live/icons",
  base_url: "http://your-domain.com"
}

# Pipeline used for user provided content on the web
MarkdownPipeline = HTMLPipeline.new (
  text_filters: [HTMLPipeline::TextFilter::ImageFilter.new],
  convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new,
  node_filters: [
    HTMLPipeline::NodeFilter::HttpsFilter.new,HTMLPipeline::NodeFilter::MentionFilter.new,
  ], context: context)

# Pipelines aren't limited to the web. You can use them for email
# processing also.
HtmlEmailPipeline = HTMLPipeline.new(
  text_filters: [
    PlainTextInputFilter.new,
    ImageFilter.new
  ], {})
```

## Filters

### TextFilters

`TextFilter`s must define a method named `call` which is called on the text. `@text`, `@config`, and `@result` are available to use, and any changes made to these ivars are passed on to the next filter.

- `ImageFilter` - converts image `url` into `<img>` tag
- `PlainTextInputFilter` - html escape text and wrap the result in a `<div>`

### ConvertFilter

The `ConvertFilter` takes text and turns it into HTML. `@text`, `@config`, and `@result` are available to use. `ConvertFilter` must defined a method named `call`, taking one argument, `text`. `call` must return a string representing the new HTML document.

- `MarkdownFilter` - creates HTML from text using [Commonmarker](https://www.github.com/gjtorikian/commonmarker)

### Sanitization

Because the web can be a scary place, **HTML is automatically sanitized** after the `ConvertFilter` runs and before the `NodeFilter`s are processed. This is to prevent malicious or unexpected input from entering the pipeline.

The sanitization process takes a hash configuration of settings. See the [Selma](https://www.github.com/gjtorikian/selma) documentation for more information on how to configure these settings. Note that users must correctly configure the sanitization configuration if they expect to use it correctly in conjunction with handlers which manipulate HTML.

A default sanitization config is provided by this library (`HTMLPipeline::SanitizationFilter::DEFAULT_CONFIG`). A sample custom sanitization allowlist might look like this:

```ruby
ALLOWLIST = {
  elements: ["p", "pre", "code"]
}

pipeline = HTMLPipeline.new \
  text_filters: [
    HTMLPipeline::TextFilter::ImageFilter.new,
  ],
  convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new,
  sanitization_config: ALLOWLIST

result = pipeline.call <<-CODE
This is *great*:

    some_code(:first)

CODE
result[:output].to_s
```

This would print:

```html
<p>This is great:</p>
<pre><code>some_code(:first)
</code></pre>
```

Sanitization can be disabled if and only if `nil` is explicitly passed as
the config:

```ruby
pipeline = HTMLPipeline.new \
  text_filters: [
    HTMLPipeline::TextFilter::ImageFilter.new,
  ],
  convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new,
  sanitization_config: nil
```

For more examples of customizing the sanitization process to include the tags you want, check out [the tests](test/sanitization_filter_test.rb) and [the FAQ](#faq).

### NodeFilters

`NodeFilters`s can operate either on HTML elements or text nodes using CSS selectors. Each `NodeFilter` must define a method named `selector` which provides an instance of `Selma::Selector`. If elements are being manipulated, `handle_element` must be defined, taking one argument, `element`; if text nodes are being manipulated, `handle_text_chunk` must be defined, taking one argument, `text_chunk`. `@config`, and `@result` are available to use, and any changes made to these ivars are passed on to the next filter.

`NodeFilter` also has an optional method, `after_initialize`, which is run after the filter initializes. This can be useful in setting up a fresh custom state for `result` to start from each time the pipeline is called.

Here's an example `NodeFilter` that adds a base url to images that are root relative:

```ruby
require 'uri'

class RootRelativeFilter < HTMLPipeline::NodeFilter

  SELECTOR = Selma::Selector.new(match_element: "img")

  def selector
    SELECTOR
  end

  def handle_element(img)
    next if img['src'].nil?
    src = img['src'].strip
    if src.start_with? '/'
      img["src"] = URI.join(context[:base_url], src).to_s
    end
  end
end
```

For more information on how to write effective `NodeFilter`s, refer to the provided filters, and see the underlying lib, [Selma](https://www.github.com/gjtorikian/selma) for more information.

- `AbsoluteSourceFilter`: replace relative image urls with fully qualified versions
- `AssetProxyFilter`: replace image links with an encoded link to an asset server
- `EmojiFilter`: converts `:<emoji>:` to [emoji](http://www.emoji-cheat-sheet.com/)
  - (Note: the included `MarkdownFilter` will already convert emoji)
- `HttpsFilter`: Replacing http urls with https versions
- `ImageMaxWidthFilter`: link to full size image for large images
- `MentionFilter`: replace `@user` mentions with links
- `SanitizationFilter`: allow sanitize user markup
- `SyntaxHighlightFilter`: applies syntax highlighting to `pre` blocks
  - (Note: the included `MarkdownFilter` will already apply highlighting)
- `TableOfContentsFilter`: anchor headings with name attributes and generate Table of Contents html unordered list linking headings
- `TeamMentionFilter`: replace `@org/team` mentions with links

## Dependencies

Since filters can be customized to your heart's content, gem dependencies are _not_ bundled; this project doesn't know which of the default filters you might use, and as such, you must bundle each filter's gem dependencies yourself.

For example, `SyntaxHighlightFilter` uses [rouge](https://github.com/jneen/rouge)
to detect and highlight languages; to use the `SyntaxHighlightFilter`, you must add the following to your Gemfile:

```ruby
gem "rouge"
```

> **Note**
> See the [Gemfile](/Gemfile) `:test` group for any version requirements.

When developing a custom filter, call `HTMLPipeline.require_dependency` at the start to ensure that the local machine has the necessary dependency. You can also use `HTMLPipeline.require_dependencies` to provide a list of dependencies to check.

On a similar note, you must manually require whichever filters you desire:

```ruby
require "html_pipeline" # must be included
require "html_pipeline/convert_filter/markdown_filter" # included because you want to use this filter
require "html_pipeline/node_filter/mention_filter" # included because you want to use this filter
```

## Documentation

Full reference documentation can be [found here](http://rubydoc.info/gems/html-pipeline/frames).

## Instrumenting

Filters and Pipelines can be set up to be instrumented when called. The pipeline
must be setup with an
[ActiveSupport::Notifications](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html)
compatible service object and a name. New pipeline objects will default to the
`HTMLPipeline.default_instrumentation_service` object.

```ruby
# the AS::Notifications-compatible service object
service = ActiveSupport::Notifications

# instrument a specific pipeline
pipeline = HTMLPipeline.new [MarkdownFilter], context
pipeline.setup_instrumentation "MarkdownPipeline", service

# or set default instrumentation service for all new pipelines
HTMLPipeline.default_instrumentation_service = service
pipeline = HTMLPipeline.new [MarkdownFilter], context
pipeline.setup_instrumentation "MarkdownPipeline"
```

Filters are instrumented when they are run through the pipeline. A
`call_filter.html_pipeline` event is published once any filter finishes; `call_text_filters`
and `call_node_filters` is published when all of the text and node filters are finished, respectively.
The `payload` should include the `filter` name. Each filter will trigger its own
instrumentation call.

```ruby
service.subscribe "call_filter.html_pipeline" do |event, start, ending, transaction_id, payload|
  payload[:pipeline] #=> "MarkdownPipeline", set with `setup_instrumentation`
  payload[:filter] #=> "MarkdownFilter"
  payload[:context] #=> context Hash
  payload[:result] #=> instance of result class
  payload[:result][:output] #=> output HTML String
end
```

The full pipeline is also instrumented:

```ruby
service.subscribe "call_text_filters.html_pipeline" do |event, start, ending, transaction_id, payload|
  payload[:pipeline] #=> "MarkdownPipeline", set with `setup_instrumentation`
  payload[:filters] #=> ["MarkdownFilter"]
  payload[:doc] #=> HTML String
  payload[:context] #=> context Hash
  payload[:result] #=> instance of result class
  payload[:result][:output] #=> output HTML String
end
```

## FAQ

### 1. Why doesn't my pipeline work when there's no root element in the document?

To make a pipeline work on a plain text document, put the `PlainTextInputFilter`
at the end of your `text_filter`s config . This will wrap the content in a `div` so the filters have a root element to work with. If you're passing in an HTML fragment,
but it doesn't have a root element, you can wrap the content in a `div`
yourself.

### 2. How do I customize an allowlist for `SanitizationFilter`s?

`HTMLPipeline::SanitizationFilter::ALLOWLIST` is the default allowlist used if no `sanitization_config`
argument is given. The default is a good starting template for
you to add additional elements. You can either modify the constant's value, or
re-define your own config and pass that in, such as:

```ruby
config = HTMLPipeline::SanitizationFilter::DEFAULT_CONFIG.deep_dup
config[:elements] << "iframe" # sure, whatever you want
```

### Contributors

Thanks to all of [these contributors](https://github.com/gjtorikian/html-pipeline/graphs/contributors).

This project is a member of the [OSS Manifesto](http://ossmanifesto.org/).

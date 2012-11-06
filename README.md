# HTML::Pipeline [![Build Status](https://secure.travis-ci.org/jch/html-pipeline.png)](http://travis-ci.org/jch/html-pipeline)

GitHub HTML processing filters and utilities. This module includes a small
framework for defining DOM based content filters and applying them to user
provided content.

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
result = pipeline.call <<CODE
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
* `AutoLinkFilter` - auto_linking urls in HTML
* `CamoFilter` - replace http image urls with [camo-fied](https://github.com/github/camo) https versions
* `EmailReplyFilter` - util filter for working with emails
* `EmojiFilter` - everyone loves [emoji](http://www.emoji-cheat-sheet.com/)!
* `ImageMaxWidthFilter` - link to full size image for large images
* `MarkdownFilter` - convert markdown to html
* `PlainTextInputFilter` - html escape text and wrap the result in a div
* `SanitizationFilter` - whitelist santize user markup
* `SyntaxHighlightFilter` - code syntax highlighter with [linguist](https://github.com/github/linguist)
* `TextileFilter` - convert textile to html
* `TableOfContentsFilter` - anchor headings with name attributes

## Development Setup

```sh
bundle
rake test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## TODO

* test whether emoji filter works on heroku
* test whether nokogiri monkey patch is still necessary

## Contributors

* [Aman Gupta](mailto:aman@tmm1.net)
* [Jake Boxer](mailto:jake@github.com)
* [Joshua Peek](mailto:josh@joshpeek.com)
* [Kyle Neath](mailto:kneath@gmail.com)
* [Rob Sanheim](mailto:rsanheim@gmail.com)
* [Simon Rozet](mailto:simon@rozet.name)
* [Vicent Martí](mailto:tanoku@gmail.com)
* [Risk :danger: Olson](mailto:technoweenie@gmail.com)

# HTML::Pipeline

GitHub HTML processing filters and utilities. This module includes a small
framework for defining DOM based content filters and applying them to user
provided content.

## Installation

Add this line to your application's Gemfile:

    gem 'html-pipeline'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install html-pipeline

## Usage

This library provides a handful of HTML filters which can be used to convert
user content HTML into something amazing.

Each filter takes an HTML string of Nokogiri::HTML::DocumentFragment then
performs modifications and/or writes information to the result hash.

For example, turning Markdown source into Markdown HTML. Or `:smile:` into
something like <img src='/emoji/smile.png'>.

Filters can be combined into a pipeline which causes each filter to hand
its output to the next filter's input, or to return a result.

Let's convert Markdown source to Markdown HTML;

    puts HTML::Pipeline::MarkdownFilter.call("Hi **world**!")

Prints:

    <p>Hi <strong>world</strong>!</p>

Even better, let's make a pipeline that supports Markdown and syntax
highlighting:

    MarkdownPipeline = HTML::Pipeline::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::SyntaxHighlightFilter
    ]
    result = MarkdownPipeline.call <<code
    This is *great*:
    ````ruby
    some_ruby_code(:first)
    ````
    code
    puts result[:output].to_s

Prints:

    <p>This is <em>great</em>:</p>

    <div class="highlight">
    <pre><span class="nb">puts</span> <span class="ss">:hi</span>
    </pre>
    </div>

## Development Setup

```
script/bootstrap
rake test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## TODO

* emoji gem is private, can't add to gemspec. specify manually for now
* autolink_filter depends on Github.enterprise?
* test whether nokogiri monkey patch is still necessary

## Contributors

* [Aman Gupta](aman@tmm1.net)
* [Jake Boxer](jake@github.com)
* [Joshua Peek](josh@joshpeek.com)
* [Kyle Neath](kneath@gmail.com)
* [Rob Sanheim](rsanheim@gmail.com)
* [Simon Rozet](simon@rozet.name)
* [Vicent Martí](tanoku@gmail.com)
* [Risk :danger: Olson](technoweenie@gmail.com)

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

TODO: Write usage instructions here

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
* syntax highlighter filter requires other github specific things
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

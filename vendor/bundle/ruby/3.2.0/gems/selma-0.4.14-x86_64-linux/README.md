# Selma

Selma **sel**ects and **ma**tches HTML nodes using CSS rules. (It can also reject/delete nodes, but then the name isn't as cool.) It's mostly an idiomatic wrapper around Cloudflare's [lol-html](https://github.com/cloudflare/lol-html) project.

![Principal Skinner asking Selma after their date: 'Isn't it nice we hate the same things?'](https://user-images.githubusercontent.com/64050/207155384-14e8bd40-780c-466f-bfff-31a8a8fc3d25.jpg)

Selma's strength (aside from being backed by Rust) is that HTML content is parsed _once_ and can be manipulated multiple times.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'selma'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install selma

## Usage

Selma can perform two different actions, either independently or together:

- Sanitize HTML, through a [Sanitize](https://github.com/rgrove/sanitize)-like allowlist syntax; and
- Select HTML using CSS rules, and manipulate elements and text nodes along the way.

It does this through two kwargs: `sanitizer` and `handlers`. The basic API for Selma looks like this:

```ruby
sanitizer_config = {
   elements: ["b", "em", "i", "strong", "u"],
}
sanitizer = Selma::Sanitizer.new(sanitizer_config)
rewriter = Selma::Rewriter.new(sanitizer: sanitizer, handlers: [MatchElementRewrite.new, MatchTextRewrite.new])
# removes any element that is not  ["b", "em", "i", "strong", "u"];
# then calls `MatchElementRewrite` and `MatchTextRewrite` on matching HTML elements
rewriter.rewrite(html)
```

Here's a look at each individual part.

### Sanitization config

Selma sanitizes by default. That is, even if the `sanitizer` kwarg is not passed in, sanitization occurs. If you truly want to disable HTML sanitization (for some reason), pass `nil`:

```ruby
Selma::Rewriter.new(sanitizer: nil) # dangerous and ill-advised
```

The configuration for the sanitization process is based on the follow key-value hash allowlist:

```ruby
# Whether or not to allow HTML comments.
allow_comments: false,

# Whether or not to allow well-formed HTML doctype declarations such as
# "<!DOCTYPE html>" when sanitizing a document.
allow_doctype: false,

# HTML elements to allow. By default, no elements are allowed (which means
# that all HTML will be stripped).
elements: ["a", "b", "img", ],

# HTML attributes to allow in specific elements. The key is the name of the element,
# and the value is an array of allowed attributes. By default, no attributes
# are allowed.
attributes: {
    "a" => ["href"],
    "img" => ["src"],
},

# URL handling protocols to allow in specific attributes. By default, no
# protocols are allowed. Use :relative in place of a protocol if you want
# to allow relative URLs sans protocol. Set to `:all` to allow any protocol.
protocols: {
    "a" => { "href" => ["http", "https", "mailto", :relative] },
    "img" => { "href" => ["http", "https"] },
},

# An Array of element names whose contents will be removed. The contents
# of all other filtered elements will be left behind.
remove_contents: ["iframe", "math", "noembed", "noframes", "noscript"],

# Elements which, when removed, should have their contents surrounded by
# whitespace.
whitespace_elements: ["blockquote", "h1", "h2", "h3", "h4", "h5", "h6", ]
```

### Defining handlers

The real power in Selma comes in its use of handlers. A handler is simply an object with various methods defined:

- `selector`, a method which MUST return an instance of `Selma::Selector`, defining the CSS classes to match
- `handle_element`, a method that's called on each matched element
- `handle_text_chunk`, a method that's called on each matched text node

Here's an example which rewrites the `href` attribute on `a` and the `src` attribute on `img` to be `https` rather than `http`.

```ruby
class MatchAttribute
  SELECTOR = Selma::Selector.new(match_element: %(a[href^="http:"], img[src^="http:"]"))

  def selector
    SELECTOR
  end

  def handle_element(element)
    if element.tag_name == "a"
      element["href"] = rename_http(element["href"])
    elsif element.tag_name == "img"
      element["src"] = rename_http(element["src"])
    end
  end

  private def rename_http(link)
    link.sub("http", "https")
  end
end

rewriter = Selma::Rewriter.new(handlers: [MatchAttribute.new])
```

The `Selma::Selector` object has three possible kwargs:

- `match_element`: any element which matches this CSS rule will be passed on to `handle_element`
- `match_text_within`: any text_chunk which matches this CSS rule will be passed on to `handle_text_chunk`
- `ignore_text_within`: this is an array of element names whose text contents will be ignored

Here's an example for `handle_text_chunk` which changes strings in various elements which are _not_ `pre` or `code`:

```ruby
class MatchText
  SELECTOR = Selma::Selector.new(match_text_within: "*", ignore_text_within: ["pre", "code"])

  def selector
    SELECTOR
  end

  def handle_text_chunk(text)
    text.replace(text.to_s, text.sub(/@.+/, "<a href=\"www.yetto.app/#{Regexp.last_match}\">"))
  end
end

rewriter = Selma::Rewriter.new(handlers: [MatchText.new])
```

#### `element` methods

The `element` argument in `handle_element` has the following methods:

- `tag_name`: Gets the element's name
- `tag_name=`: Sets the element's name
- `self_closing?`: A bool which identifies whether or not the element is self-closing
- `[]`: Get an attribute
- `[]=`: Set an attribute
- `remove_attribute`: Remove an attribute
- `has_attribute?`: A bool which identifies whether or not the element has an attribute
- `attributes`: List all the attributes
- `ancestors`: List all of an element's ancestors as an array of strings
- `before(content, as: content_type)`: Inserts `content` before the element. `content_type` is either `:text` or `:html` and determines how the content will be applied.
- `after(content, as: content_type)`: Inserts `content` after the element. `content_type` is either `:text` or `:html` and determines how the content will be applied.
- `prepend(content, as: content_type)`: prepends `content` to the element's inner content, i.e. inserts content right after the element's start tag. `content_type` is either `:text` or `:html` and determines how the content will be applied.
- `append(content, as: content_type)`: appends `content` to the element's inner content, i.e. inserts content right before the element's end tag. `content_type` is either `:text` or `:html` and determines how the content will be applied.
- `set_inner_content`: Replaces inner content of the element with `content`. `content_type` is either `:text` or `:html` and determines how the content will be applied.
- `remove`: Removes the element and its inner content.
- `remove_and_keep_content`: Removes the element, but keeps its content. I.e. remove start and end tags of the element.
- `removed?`: A bool which identifies if the element has been removed or replaced with some content.

#### `text_chunk` methods

- `to_s` / `.content`: Gets the text node's content
- `text_type`: identifies the type of text in the text node
- `before(content, as: content_type)`: Inserts `content` before the text. `content_type` is either `:text` or `:html` and determines how the content will be applied.
- `after(content, as: content_type)`: Inserts `content` after the text. `content_type` is either `:text` or `:html` and determines how the content will be applied.
- `replace(content, as: content_type)`: Replaces the text node with `content`. `content_type` is either `:text` or `:html` and determines how the content will be applied.

## Security

Theoretically, a malicious user can provide a very large document for processing, which can exhaust the memory of the host machine. To set a limit on how much string content is processed at once, you can provide `memory` options:

```ruby
Selma::Rewriter.new(options: { memory: { max_allowed_memory_usage: 1_000_000 } }) # ~1MB
```

The structure of the `memory` options looks like this:

```ruby
{
  memory: {
    max_allowed_memory_usage: 1000,
    preallocated_parsing_buffer_size: 100,
  }
}
```

Note that `preallocated_parsing_buffer_size` must always be less than `max_allowed_memory_usage`. See [the`lol_html` project documentation](https://docs.rs/lol_html/1.2.1/lol_html/struct.MemorySettings.html) to learn more about the default values.

## Benchmarks

When `bundle exec rake benchmark`, two different benchmarks are calculated. Here are those results on my machine.

### Benchmarks for just the sanitization process

Comparing Selma against popular Ruby sanitization gems:

<!-- prettier-ignore-start -->
<details>
<pre>
input size = 25309 bytes, 0.03 MB

ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
Warming up --------------------------------------
sanitize-sm 15.000 i/100ms
selma-sm 127.000 i/100ms
Calculating -------------------------------------
sanitize-sm 157.643 (± 1.9%) i/s - 4.740k in 30.077172s
selma-sm 1.278k (± 1.5%) i/s - 38.354k in 30.019722s

Comparison:
selma-sm: 1277.9 i/s
sanitize-sm: 157.6 i/s - 8.11x slower

input size = 86686 bytes, 0.09 MB

ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
Warming up --------------------------------------
sanitize-md 4.000 i/100ms
selma-md 33.000 i/100ms
Calculating -------------------------------------
sanitize-md 40.034 (± 5.0%) i/s - 1.200k in 30.043322s
selma-md 332.959 (± 2.1%) i/s - 9.999k in 30.045733s

Comparison:
selma-md: 333.0 i/s
sanitize-md: 40.0 i/s - 8.32x slower

input size = 7172510 bytes, 7.17 MB

ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
Warming up --------------------------------------
sanitize-lg 1.000 i/100ms
selma-lg 1.000 i/100ms
Calculating -------------------------------------
sanitize-lg 0.141 (± 0.0%) i/s - 5.000 in 35.426127s
selma-lg 3.963 (± 0.0%) i/s - 119.000 in 30.037386s

Comparison:
selma-lg: 4.0 i/s
sanitize-lg: 0.1 i/s - 28.03x slower

</pre>
</details>
<!-- prettier-ignore-end -->

### Benchmarks for just the rewriting process

Comparing Selma against popular Ruby HTML parsing gems:

<!-- prettier-ignore-start -->
<details>
<pre>
input size = 25309 bytes, 0.03 MB

ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
Warming up --------------------------------------
nokogiri-sm 79.000 i/100ms
nokolexbor-sm 295.000 i/100ms
selma-sm 237.000 i/100ms
Calculating -------------------------------------
nokogiri-sm 800.531 (± 2.2%) i/s - 24.016k in 30.016056s
nokolexbor-sm 3.033k (± 3.6%) i/s - 91.155k in 30.094884s
selma-sm 2.386k (± 1.6%) i/s - 71.574k in 30.001701s

Comparison:
nokolexbor-sm: 3033.1 i/s
selma-sm: 2386.3 i/s - 1.27x slower
nokogiri-sm: 800.5 i/s - 3.79x slower

input size = 86686 bytes, 0.09 MB

ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
Warming up --------------------------------------
nokogiri-md 8.000 i/100ms
nokolexbor-md 43.000 i/100ms
selma-md 38.000 i/100ms
Calculating -------------------------------------
nokogiri-md 85.013 (± 8.2%) i/s - 2.024k in 52.257472s
nokolexbor-md 416.074 (±11.1%) i/s - 12.341k in 30.111613s
selma-md 361.471 (± 4.7%) i/s - 10.830k in 30.033997s

Comparison:
nokolexbor-md: 416.1 i/s
selma-md: 361.5 i/s - same-ish: difference falls within error
nokogiri-md: 85.0 i/s - 4.89x slower

input size = 7172510 bytes, 7.17 MB

ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
Warming up --------------------------------------
nokogiri-lg 1.000 i/100ms
nokolexbor-lg 1.000 i/100ms
selma-lg 1.000 i/100ms
Calculating -------------------------------------
nokogiri-lg 0.805 (± 0.0%) i/s - 25.000 in 31.148730s
nokolexbor-lg 2.194 (± 0.0%) i/s - 66.000 in 30.278108s
selma-lg 5.541 (± 0.0%) i/s - 166.000 in 30.037197s

Comparison:
selma-lg: 5.5 i/s
nokolexbor-lg: 2.2 i/s - 2.53x slower
nokogiri-lg: 0.8 i/s - 6.88x slower

</pre>
</details>
<!-- prettier-ignore-end -->

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gjtorikian/selma. This project is a safe, welcoming space for collaboration.

## Acknowledgements

- https://github.com/flavorjones/ruby-c-extensions-explained#strategy-3-precompiled and [Nokogiri](https://github.com/sparklemotion/nokogiri) for hints on how to ship precompiled cross-platform gems
- @vmg for his work at GitHub on goomba, from which some design patterns were learned
- [sanitize](https://github.com/rgrove/sanitize) for a comprehensive configuration API and test suite

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

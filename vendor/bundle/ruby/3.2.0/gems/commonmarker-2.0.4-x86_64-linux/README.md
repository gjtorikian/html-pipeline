# Commonmarker

Ruby wrapper for Rust's [comrak](https://github.com/kivikakk/comrak) crate.

It passes all of the CommonMark test suite, and is therefore spec-complete. It also includes extensions to the CommonMark spec as documented in the [GitHub Flavored Markdown spec](http://github.github.com/gfm/), such as support for tables, strikethroughs, and autolinking.

> [!NOTE]
> By default, several extensions not in any spec have been enabled, for the sake of end user convenience when generating HTML.
>
> For more information on the available options and extensions, see [the documentation below](#options-and-plugins).

## Installation

Add this line to your application's Gemfile:

    gem 'commonmarker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install commonmarker

## Usage

### Converting to HTML

Call `to_html` on a string to convert it to HTML:

```ruby
require 'commonmarker'
Commonmarker.to_html('"Hi *there*"', options: {
    parse: { smart: true }
})
# => <p>“Hi <em>there</em>”</p>\n
```

(The second argument is optional--[see below](#options-and-plugins) for more information.)

### Generating a document

You can also parse a string to receive a `:document` node. You can then print that node to HTML, iterate over the children, and do other fun node stuff. For example:

```ruby
require 'commonmarker'

doc = Commonmarker.parse("*Hello* world", options: {
    parse: { smart: true }
})
puts(doc.to_html) # => <p><em>Hello</em> world</p>\n

doc.walk do |node|
  puts node.type # => [:document, :paragraph, :emph, :text, :text]
end
```

(The second argument is optional--[see below](#options-and-plugins) for more information.)

When it comes to modifying the document, you can perform the following operations:

- `insert_before`
- `insert_after`
- `prepend_child`
- `append_child`
- `delete`

You can also get the source position of a node by calling `source_position`:

```ruby
doc = Commonmarker.parse("*Hello* world")
puts doc.first_child.first_child.source_position
# => {:start_line=>1, :start_column=>1, :end_line=>1, :end_column=>7}
```

You can also modify the following attributes:

- `url`
- `title`
- `header_level`
- `list_type`
- `list_start`
- `list_tight`
- `fence_info`

#### Example: Walking the AST

You can use `walk` or `each` to iterate over nodes:

- `walk` will iterate on a node and recursively iterate on a node's children.
- `each` will iterate on a node's direct children, but no further.

```ruby
require 'commonmarker'

# parse some string
doc = Commonmarker.parse("# The site\n\n [GitHub](https://www.github.com)")

# Walk tree and print out URLs for links
doc.walk do |node|
  if node.type == :link
    printf("URL = %s\n", node.url)
  end
end
# => URL = https://www.github.com

# Transform links to regular text
doc.walk do |node|
  if node.type == :link
    node.insert_before(node.first_child)
    node.delete
  end
end
# => <h1><a href=\"#the-site\"></a>The site</h1>\n<p>GitHub</p>\n
```

#### Example: Converting a document back into raw CommonMark

You can use `to_commonmark` on a node to render it as raw text:

```ruby
require 'commonmarker'

# parse some string
doc = Commonmarker.parse("# The site\n\n [GitHub](https://www.github.com)")

# Transform links to regular text
doc.walk do |node|
  if node.type == :link
    node.insert_before(node.first_child)
    node.delete
  end
end

doc.to_commonmark
# => # The site\n\nGitHub\n
```

## Options and plugins

### Options

Commonmarker accepts the same parse, render, and extensions options that comrak does, as a hash dictionary with symbol keys:

```ruby
Commonmarker.to_html('"Hi *there*"', options:{
  parse: { smart: true },
  render: { hardbreaks: false}
})
```

Note that there is a distinction in comrak for "parse" options and "render" options, which are represented in the tables below. As well, if you wish to disable any-non boolean option, pass in `nil`.

### Parse options

| Name                        | Description                                                                                                                                 | Default |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `smart`                     | Punctuation (quotes, full-stops and hyphens) are converted into 'smart' punctuation.                                                        | `false` |
| `default_info_string`       | The default info string for fenced code blocks.                                                                                             | `""`    |
| `relaxed_tasklist_matching` | Enables relaxing of the tasklist extension matching, allowing any non-space to be used for the "checked" state instead of only `x` and `X`. | `false` |
| `relaxed_autolinks`         | Enable relaxing of the autolink extension parsing, allowing links to be recognized when in brackets, as well as permitting any url scheme.  | `false` |

### Render options

| Name                 | Description                                                                                            | Default |
| -------------------- | ------------------------------------------------------------------------------------------------------ | ------- |
| `hardbreaks`         | [Soft line breaks](http://spec.commonmark.org/0.27/#soft-line-breaks) translate into hard line breaks. | `true`  |
| `github_pre_lang`    | GitHub-style `<pre lang="xyz">` is used for fenced code blocks with info tags.                         | `true`  |
| `full_info_string`   | Gives info string data after a space in a `data-meta` attribute on code blocks.                        | `false` |
| `width`              | The wrap column when outputting CommonMark.                                                            | `80`    |
| `unsafe`             | Allow rendering of raw HTML and potentially dangerous links.                                           | `false` |
| `escape`             | Escape raw HTML instead of clobbering it.                                                              | `false` |
| `sourcepos`          | Include source position attribute in HTML and XML output.                                              | `false` |
| `escaped_char_spans` | Wrap escaped characters in span tags.                                                                  | `true`  |
| `ignore_setext`      | Ignores setext-style headings.                                                                         | `false` |
| `ignore_empty_links` | Ignores empty links, leaving the Markdown text in place.                                               | `false` |
| `gfm_quirks`         | Outputs HTML with GFM-style quirks; namely, not nesting `<strong>` inlines.                            | `false` |
| `prefer_fenced`      | Always output fenced code blocks, even where an indented one could be used.                            | `false` |

As well, there are several extensions which you can toggle in the same manner:

```ruby
Commonmarker.to_html('"Hi *there*"', options: {
    extension: { footnotes: true, description_lists: true },
    render: { hardbreaks: false }
})
```

### Extension options

| Name                          | Description                                                                                                         | Default |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------- |
| `strikethrough`               | Enables the [strikethrough extension](https://github.github.com/gfm/#strikethrough-extension-) from the GFM spec.   | `true`  |
| `tagfilter`                   | Enables the [tagfilter extension](https://github.github.com/gfm/#disallowed-raw-html-extension-) from the GFM spec. | `true`  |
| `table`                       | Enables the [table extension](https://github.github.com/gfm/#tables-extension-) from the GFM spec.                  | `true`  |
| `autolink`                    | Enables the [autolink extension](https://github.github.com/gfm/#autolinks-extension-) from the GFM spec.            | `true`  |
| `tasklist`                    | Enables the [task list extension](https://github.github.com/gfm/#task-list-items-extension-) from the GFM spec.     | `true`  |
| `superscript`                 | Enables the superscript Comrak extension.                                                                           | `false` |
| `header_ids`                  | Enables the header IDs Comrak extension. from the GFM spec.                                                         | `""`    |
| `footnotes`                   | Enables the footnotes extension per `cmark-gfm`.                                                                    | `false` |
| `description_lists`           | Enables the description lists extension.                                                                            | `false` |
| `front_matter_delimiter`      | Enables the front matter extension.                                                                                 | `""`    |
| `multiline_block_quotes`      | Enables the multiline block quotes extension.                                                                       | `false` |
| `math_dollars`, `math_code`   | Enables the math extension.                                                                                         | `false` |
| `shortcodes`                  | Enables the shortcodes extension.                                                                                   | `true`  |
| `wikilinks_title_before_pipe` | Enables the wikilinks extension, placing the title before the dividing pipe.                                        | `false` |
| `wikilinks_title_after_pipe`  | Enables the shortcodes extension, placing the title after the dividing pipe.                                        | `false` |
| `underline`                   | Enables the underline extension.                                                                                    | `false` |
| `spoiler`                     | Enables the spoiler extension.                                                                                      | `false` |
| `greentext`                   | Enables the greentext extension.                                                                                    | `false` |
| `subscript`                   | Enables the subscript extension.                                                                                    | `false` |
| `alerts`                      | Enables the alerts extension.                                                                                       | `false` |

For more information on these options, see [the comrak documentation](https://github.com/kivikakk/comrak#usage).

### Plugins

In addition to the possibilities provided by generic CommonMark rendering, Commonmarker also supports plugins as a means of
providing further niceties.

#### Syntax Highlighter Plugin

The library comes with [a set of pre-existing themes](https://docs.rs/syntect/5.0.0/syntect/highlighting/struct.ThemeSet.html#implementations) for highlighting code:

- `"base16-ocean.dark"`
- `"base16-eighties.dark"`
- `"base16-mocha.dark"`
- `"base16-ocean.light"`
- `"InspiredGitHub"`
- `"Solarized (dark)"`
- `"Solarized (light)"`

````ruby
code = <<~CODE
  ```ruby
  def hello
    puts "hello"
  end
  ```
CODE

# pass in a theme name from a pre-existing set
puts Commonmarker.to_html(code, plugins: { syntax_highlighter: { theme: "InspiredGitHub" } })

# <pre style="background-color:#ffffff;" lang="ruby"><code>
# <span style="font-weight:bold;color:#a71d5d;">def </span><span style="font-weight:bold;color:#795da3;">hello
# </span><span style="color:#62a35c;">puts </span><span style="color:#183691;">&quot;hello&quot;
# </span><span style="font-weight:bold;color:#a71d5d;">end
# </span>
# </code></pre>
````

By default, the plugin uses the `"base16-ocean.dark"` theme to syntax highlight code.

To disable this plugin, set the value to `nil`:

````ruby
code = <<~CODE
  ```ruby
  def hello
    puts "hello"
  end
  ```
CODE

Commonmarker.to_html(code, plugins: { syntax_highlighter: nil })

# <pre lang="ruby"><code>def hello
#   puts &quot;hello&quot;
# end
# </code></pre>
````

To output CSS classes instead of `style` attributes, set the `theme` key to `""`:

````ruby
code = <<~CODE
  ```ruby
  def hello
    puts "hello"
  end
CODE

Commonmarker.to_html(code, plugins: { syntax_highlighter: { theme: "" } })

# <pre class="syntax-highlighting"><code><span class="source ruby"><span class="meta function ruby"><span class="keyword control def ruby">def</span></span><span class="meta function ruby"> # <span class="entity name function ruby">hello</span></span>
#   <span class="support function builtin ruby">puts</span> <span class="string quoted double ruby"><span class="punctuation definition string begin ruby">&quot;</span>hello<span class="punctuation definition string end ruby">&quot;</span></span>
# <span class="keyword control ruby">end</span>\n</span></code></pre>
````

To use a custom theme, you can provide a `path` to a directory containing `.tmtheme` files to load:

```ruby
Commonmarker.to_html(code, plugins: { syntax_highlighter: { theme: "Monokai", path: "./themes" } })
```

## Output formats

Commonmarker can currently only generate output in one format: HTML.

### HTML

```ruby
puts Commonmarker.to_html('*Hello* world!')

# <p><em>Hello</em> world!</p>
```

## Developing locally

After cloning the repo:

```
script/bootstrap
bundle exec rake compile
```

If there were no errors, you're done! Otherwise, make sure to follow the comrak dependency instructions.

## Benchmarks

```
❯ bundle exec rake benchmark
input size = 11064832 bytes

ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
Warming up --------------------------------------
  Markly.render_html     1.000 i/100ms
Markly::Node#to_html     1.000 i/100ms
Commonmarker.to_html     1.000 i/100ms
Commonmarker::Node.to_html
                         1.000 i/100ms
Kramdown::Document#to_html
                         1.000 i/100ms
Calculating -------------------------------------
  Markly.render_html     15.606 (±25.6%) i/s -     71.000 in   5.047132s
Markly::Node#to_html     15.692 (±25.5%) i/s -     72.000 in   5.095810s
Commonmarker.to_html      4.482 (± 0.0%) i/s -     23.000 in   5.137680s
Commonmarker::Node.to_html
                          5.092 (±19.6%) i/s -     25.000 in   5.072220s
Kramdown::Document#to_html
                          0.379 (± 0.0%) i/s -      2.000 in   5.277770s

Comparison:
Markly::Node#to_html:       15.7 i/s
  Markly.render_html:       15.6 i/s - same-ish: difference falls within error
Commonmarker::Node.to_html:        5.1 i/s - 3.08x  slower
Commonmarker.to_html:        4.5 i/s - 3.50x  slower
Kramdown::Document#to_html:        0.4 i/s - 41.40x  slower
```

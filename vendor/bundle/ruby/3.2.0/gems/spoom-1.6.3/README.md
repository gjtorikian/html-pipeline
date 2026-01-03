# Spoom

Useful tools for Sorbet enthusiasts.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'spoom'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spoom

## Usage

`spoom` provides both a CLI and an API to interact with Sorbet.

### Generate a typing coverage report

Spoom can create a typing coverage report from Sorbet and Git data:

![Coverage Report](docs/report.png)

After installing the `spoom` gem, run the `timeline` command to collect the history data:

```
$ spoom srb coverage timeline --save
```

Then create the HTML page with `report`:

```
$ spoom srb coverage report
```

Your report will be generated under `spoom_report.html`.

See all the [Typing Coverage](#typing-coverage) CLI commands for more details.

### Command Line Interface

#### Errors sorting and filtering

List all typechecking errors sorted by location:

```
$ spoom srb tc -s loc
```

List all typechecking errors sorted by error code first:

```
$ spoom srb tc -s code
```

List only typechecking errors from a specific error code:

```
$ spoom srb tc -c 7004
```

List only the first 10 typechecking errors

```
$ spoom srb tc -l 10
```

These options can be combined:

```
$ spoom srb tc -s -c 7004 -l 10
```

Remove duplicated error lines:

```
$ spoom srb tc -u
```

Format each error line:

```
$ spoom srb tc -f '%C - %F:%L: %M'
```

Where:

* `%C` is the error code
* `%F` is the file the error is from
* `%L` is the line the error is from
* `%M` is the error message

Hide the `Errors: X` at the end of the list:

```
$ spoom srb tc --no-count
```

List only the errors coming from specific directories or files:

```
$ spoom srb tc file1.rb path1/ path2/
```

#### Typing coverage

Show metrics about the project contents and the typing coverage:

```
$ spoom srb coverage
```

Save coverage data under `spoom_data/`:

```
$ spoom srb coverage --save
```

Save coverage data under a specific directory:

```
$ spoom srb coverage --save my_data/
```

Show typing coverage evolution based on the commits history:

```
$ spoom srb coverage timeline
```

Show typing coverage evolution based on the commits history between specific dates:

```
$ spoom srb coverage timeline --from YYYY-MM-DD --to YYYY-MM-DD
```

Save the typing coverage evolution as JSON under `spoom_data/`:

```
$ spoom srb coverage timeline --save
```

Save the typing coverage evolution as JSON in a specific directory:

```
$ spoom srb coverage timeline --save my_data/
```

Run `bundle install` for each commit of the timeline (may solve errors due to different Sorbet versions):

```
$ spoom srb coverage timeline --bundle-install
```

Generate an HTML typing coverage report:

```
$ spoom srb coverage report
```

Change the colors used for strictnesses (useful for colorblind folks):

```
$ spoom srb coverage report \
  --color-true "#648ffe" \
  --color-false "#fe6002" \
  --color-ignore "#feb000" \
  --color-strict "#795ef0" \
  --color-strong "#6444f1"
```

Open the HTML typing coverage report:

```
$ spoom srb coverage open
```

#### Change the sigil used in files

Bump the strictness from all files currently at `typed: false` to `typed: true` where it does not create typechecking errors:

```
$ spoom srb bump --from false --to true
```

Bump the strictness from all files currently at `typed: false` to `typed: true` even if it creates typechecking errors:

```
$ spoom srb bump --from false --to true -f
```

Bump the strictness from a list of files (one file by line):

```
$ spoom srb bump --from false --to true -o list.txt
```

Check if files can be bumped without applying any change and show the list of files that can be bumped without errors.
Will exit with a non-zero status if some files can be bumped without errors (useful to check for bumpable files on CI for example):

```
$ spoom srb bump --from false --to true --dry
```

Bump files using a custom instance of Sorbet:

```
$ spoom srb bump --from false --to true --sorbet /path/to/sorbet/bin
```

Count the number of type-checking errors if all files were bumped to true:

```
$ spoom srb bump --count-errors --dry
```

#### Translate sigs between RBI and RBS

Translate all file sigs from RBI to RBS:

```
$ spoom srb sigs translate
```

Translate one file's sigs from RBS to RBI:

```
$ spoom srb sigs translate --from rbs --to rbi /path/to/file.rb
```

#### Interact with Sorbet LSP mode

**Experimental**

Find all definitions for `Foo`:

```
$ spoom srb lsp find Foo
```

List all symbols in a file:

```
$ spoom srb lsp symbols <file.rb>
```

List all definitions for a specific code location:

```
$ spoom srb lsp defs <file.rb> <line> <column>
```

List all references for a specific code location:

```
$ spoom srb lsp refs <file.rb> <line> <column>
```

Show hover information for a specific code location:

```
$ spoom srb lsp hover <file.rb> <line> <column>
```

Show signature information for a specific code location:

```
$ spoom srb lsp sig <file.rb> <line> <column>
```

Show type information for a specific code location:

```
$ spoom srb lsp sig <file.rb> <line> <column>
```

### API

#### Parsing Sorbet config

Parses a Sorbet config file:

```ruby
config = Spoom::Sorbet::Config.parse_file("sorbet/config")
puts config.paths   # "."
```

Parses a Sorbet config string:

```ruby
config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
  a
  --file=b
  --ignore=c
CONFIG
puts config.paths   # "a", "b"
puts config.ignore  # "c"
```

List all files typchecked by Sorbet:

```ruby
config = Spoom::Sorbet::Config.parse_file("sorbet/config")
puts Spoom::Sorbet.srb_files(config)
```

#### Parsing Sorbet metrics

Display metrics collected during typechecking:

```ruby
puts Spoom::Sorbet.srb_metrics(capture_err: false)
```

#### Interacting with LSP

Create an LSP client:

```rb
client = Spoom::LSP::Client.new(
  Spoom::Sorbet::BIN_PATH,
  "--lsp",
  "--enable-all-experimental-lsp-features",
  "--disable-watchman",
)
client.open(".")
```

Find all the symbols matching a string:

```rb
puts client.symbols("Foo")
```

Find all the symbols for a file:

```rb
puts client.document_symbols("file://path/to/my/file.rb")
```

### Backtrace Filtering

Spoom provides a backtrace filter for Minitest to remove the Sorbet frames from test failures, giving a more readable output. To enable it:

```ruby
# test/test_helper.rb
require "spoom/backtrace_filter/minitest"
Minitest.backtrace_filter = Spoom::BacktraceFilter::Minitest.new
```

### Dead code removal

Run dead code detection in your project with:

```
$ spoom deadcode
```

This will list all the methods and constants that do not appear to be used in your project.

You can remove them with Spoom:

```
$ spoom deadcode remove path/to/file.rb:42:18-47:23
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Don't forget to run `bin/sanity` before pushing your changes.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/spoom. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Spoom project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Shopify/spoom/blob/main/CODE_OF_CONDUCT.md).

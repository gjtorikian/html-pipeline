# Upgrade Guide

## From v2 to v3

HTMLPipeline v3 is a massive improvement over this still much loved (and woefully under-maintained) project. This section will attempt to list all of the breaking changes between the two versions and provide suggestions on how to upgrade.

### Changed namespace

This project is now under a module called `HTMLPipeline`, not `HTML::Pipeline`.

### Removed filters

The following filters were removed:

- `AutolinkFilter`: this is handled by [Commonmarker](https://www.github.com/gjtorikian/commonmarker) and can be disabled/enabled through the `MarkdownFilter`'s `context` hash
- `SanitizationFilter`: this is handled by [Selma](https://www.github.com/gjtorikian/selma); configuration can be done through the `sanitization_config` hash
- `EmailReplyFilter`
- `CamoFilter`

### Changed API

The new way to call this project is as follows:

```ruby
HTMLPipeline.new(
    text_filters: [], # array of instantiated (`.new`ed) `HTMLPipeline::TextFilter`
    convert_filter:, # a filter that runs to turn text into HTML
    sanitization_config: {}, # an allowlist of elements/attributes/protocols to keep
    node_filters: []) # array of instantiated (`.new`ed) `HTMLPipeline::NodeFilter`
```

Please refer to the README for more information on constructing filters. In most cases, the underlying filter needs only a few changes, primarily to make use of [Selma](https://www.github.com/gjtorikian/selma) rather than Nokogiri.

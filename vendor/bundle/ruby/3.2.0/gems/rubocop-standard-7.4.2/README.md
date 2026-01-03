# RuboCop Standard

This repository enables all of [Shopify's recommended RuboCop configurations](https://github.com/Shopify/ruby-style-guide), plus some extra ones I've found useful for my projects, like:

- [`rubocop-minitest`](https://github.com/rubocop/rubocop-minitest)
- [`rubocop-performance`](https://github.com/rubocop/rubocop-performance)
- [`rubocop-rails`](https://github.com/rubocop/rubocop-rails)
- [`rubocop-rails-accessibility`](https://github.com/github/rubocop-rails-accessibility)
- [`rubocop-rake`](https://github.com/rubocop/rubocop-rake)

## Installation

### Gemfile

```ruby
gem "rubocop-standard"
```

### .rubocop.yml

```yaml
require:
  - rubocop-standard
```

## How to configure

In your .rubocop.yml file, just write:

```yaml
inherit_gem:
  rubocop-standard:
    - config/default.yml
```

By default, `rubocop-performance` and `rubocop-rake` rules are enforced, because it's assumed that every Ruby project cares about these two sets. Why? Well, everyone should care about performance, and every project uses Rake (and Bundler) as de facto tools.

This gem also has the following Rubocop tools as dependencies:

- `rubocop-minitest`
- `rubocop-rails`
- `rubocop-rails-accessibility`
- `rubocop-sorbet`

You can add those in for whichever project needs them:

```yaml
inherit_gem:
  rubocop-standard:
    - config/default.yml
    - config/minitest.yml
    - config/rails.yml # includes rails-accessibility
```

## Other features

This project also excludes directories that are ancillary to the core lib code:

```yaml
AllCops:
  Exclude:
    - bin/**/*
    - db/**/*
    - node_modules/**/*
    - sorbet/**/*
    - tmp/**/*
    - vendor/**/*
```

Rails environments also includes `staging`:

```yml
Rails/UnknownEnv:
  Environments:
    - development
    - test
    - staging
    - production
```

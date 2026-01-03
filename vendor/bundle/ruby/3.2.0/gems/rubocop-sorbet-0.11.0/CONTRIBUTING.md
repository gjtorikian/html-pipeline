Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/rubocop-sorbet.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Creating a new cop

To contribute a new cop, please use the supplied generator like this:

```sh
bundle exec rake "new_cop[Sorbet/NewCopName]"
```

which will create a skeleton cop, a skeleton spec, an entry in the default config file and will require the new cop so that it is properly exported from the gem.

Don't forget to update the documentation with:

```sh
bundle exec rake generate_cops_documentation
```

## Releasing a new version

Update the version in the `VERSION` file.

Then run the `rake prepare_release` task.

This will update the version in the `lib/rubocop/sorbet/version.rb` file, the `config/default.yml` file, and the `Gemfile.lock` file.

It will also commit the changes, tag the release, and push the changes to the remote repository.

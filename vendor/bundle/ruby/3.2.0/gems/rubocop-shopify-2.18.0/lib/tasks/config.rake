# frozen_string_literal: true

require "rubocop"

namespace :config do
  desc "Dump the full RuboCop config as a YAML file for testing"
  task :dump, [:target] do |_task, args|
    file = "rubocop.yml"
    target = args.fetch(:target, "test/fixtures/full_config.yml")

    file_config = RuboCop::ConfigLoader.load_file(file)
    config = RuboCop::ConfigLoader.merge_with_default(file_config, file)
    output = config.to_h.to_yaml.gsub(config.base_dir_for_path_parameters, "")

    # Removing trailing whitespaces from each line due to older libyaml versions
    # converting nil hash values into whitespaces. GitHub actions is still stuck
    # with libyaml < 0.2.5. This line can be removed once it is upgraded. Psych
    # can be used to check for the running libyaml version:
    #
    # ```ruby
    # require "psych"
    # puts Psych::LIBYAML_VERSION
    # ```
    #
    # For more info, see: https://github.com/yaml/libyaml/pull/186
    output.gsub!(/\s\n/, "\n")

    File.write(target, output)
  end
end

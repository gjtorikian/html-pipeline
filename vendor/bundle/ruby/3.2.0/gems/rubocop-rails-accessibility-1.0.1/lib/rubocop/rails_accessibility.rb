# frozen_string_literal: true

require "pathname"

module RuboCop
  module RailsAccessibility
    PROJECT_ROOT   = Pathname.new(__dir__).parent.parent.expand_path.freeze
    CONFIG_DEFAULT = PROJECT_ROOT.join("config", "default.yml").freeze
  end
end

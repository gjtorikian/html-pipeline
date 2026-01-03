# frozen_string_literal: true

require "rubocop"
require "rubocop/rails_accessibility"
require "rubocop/rails_accessibility/inject"
require "rubocop/rails_accessibility/version"

RuboCop::RailsAccessibility::Inject.defaults!

require "rubocop/cop/rails_accessibility/image_has_alt"
require "rubocop/cop/rails_accessibility/no_positive_tabindex"
require "rubocop/cop/rails_accessibility/no_redundant_image_alt"

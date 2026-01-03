# frozen_string_literal: true

# Require this file to load code that supports testing using Minitest.

require 'rubocop'
require 'minitest'
require_relative 'assert_offense'

Minitest::Test.include RuboCop::Minitest::AssertOffense

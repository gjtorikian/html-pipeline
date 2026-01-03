# frozen_string_literal: true

begin
  # native precompiled gems package shared libraries in <gem_dir>/lib/commonmarker/<ruby_version>
  # load the precompiled extension file
  ruby_version = /\d+\.\d+/.match(RUBY_VERSION)
  require_relative "#{ruby_version}/commonmarker"
rescue LoadError
  # fall back to the extension compiled upon installation.
  # use "require" instead of "require_relative" because non-native gems will place C extension files
  # in Gem::BasicSpecification#extension_dir after compilation (during normal installation), which
  # is in $LOAD_PATH but not necessarily relative to this file (see nokogiri#2300)
  require "commonmarker/commonmarker"
end

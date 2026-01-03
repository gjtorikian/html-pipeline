# typed: strict
# frozen_string_literal: true

require "set"

require "tapioca"
require "tapioca/runtime/reflection"
require "tapioca/runtime/trackers"

require "benchmark"
require "bundler"
require "erb"
require "etc"
require "fileutils"
require "json"
require "logger"
require "net/http"
require "netrc"
require "parallel"
require "pathname"
require "shellwords"
require "tempfile"
require "thor"
require "yaml"
require "yard-sorbet"
require "prism"

require "tapioca/runtime/dynamic_mixin_compiler"
require "tapioca/sorbet_ext/backcompat_patches"
require "tapioca/sorbet_ext/name_patch"
require "tapioca/sorbet_ext/generic_name_patch"
require "tapioca/sorbet_ext/proc_bind_patch"
require "tapioca/runtime/generic_type_registry"

require "spoom"
require "tapioca/helpers/gem_helper"
require "tapioca/helpers/git_attributes"
require "tapioca/helpers/sorbet_helper"
require "tapioca/helpers/rbi_helper"

require "tapioca/helpers/source_uri"
require "tapioca/helpers/cli_helper"
require "tapioca/helpers/config_helper"
require "tapioca/helpers/rbi_files_helper"
require "tapioca/helpers/env_helper"

require "tapioca/repo_index"
require "tapioca/gemfile"
require "tapioca/gem_info"
require "tapioca/executor"

require "tapioca/static/symbol_table_parser"
require "tapioca/static/symbol_loader"
require "tapioca/static/requires_compiler"

require "tapioca/loaders/loader"
require "tapioca/loaders/gem"
require "tapioca/loaders/dsl"

require "tapioca/gem"
require "tapioca/dsl"
require "tapioca/commands"
require "tapioca/cli"

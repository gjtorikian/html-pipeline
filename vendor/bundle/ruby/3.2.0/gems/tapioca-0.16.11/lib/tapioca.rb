# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "rubygems/user_interaction"

module Tapioca
  extend T::Sig

  @traces = T.let([], T::Array[TracePoint])

  class << self
    extend T::Sig

    sig do
      type_parameters(:Result)
        .params(blk: T.proc.returns(T.type_parameter(:Result)))
        .returns(T.type_parameter(:Result))
    end
    def silence_warnings(&blk)
      original_verbosity = $VERBOSE
      $VERBOSE = nil
      ::Gem::DefaultUserInteraction.use_ui(::Gem::SilentUI.new) do
        blk.call
      end
    ensure
      $VERBOSE = original_verbosity
    end
  end

  class Error < StandardError; end

  LIB_ROOT_DIR = T.let(T.must(__dir__), String)
  SORBET_DIR = T.let("sorbet", String)
  SORBET_CONFIG_FILE = T.let("#{SORBET_DIR}/config", String)
  TAPIOCA_DIR = T.let("#{SORBET_DIR}/tapioca", String)
  TAPIOCA_CONFIG_FILE = T.let("#{TAPIOCA_DIR}/config.yml", String)

  BINARY_FILE = T.let("bin/tapioca", String)
  DEFAULT_POSTREQUIRE_FILE = T.let("#{TAPIOCA_DIR}/require.rb", String)
  DEFAULT_RBI_DIR = T.let("#{SORBET_DIR}/rbi", String)
  DEFAULT_DSL_DIR = T.let("#{DEFAULT_RBI_DIR}/dsl", String)
  DEFAULT_GEM_DIR = T.let("#{DEFAULT_RBI_DIR}/gems", String)
  DEFAULT_SHIM_DIR = T.let("#{DEFAULT_RBI_DIR}/shims", String)
  DEFAULT_TODO_FILE = T.let("#{DEFAULT_RBI_DIR}/todo.rbi", String)
  DEFAULT_ANNOTATIONS_DIR = T.let("#{DEFAULT_RBI_DIR}/annotations", String)

  DEFAULT_OVERRIDES = T.let(
    {
      # ActiveSupport overrides some core methods with different signatures
      # so we generate a typed: false RBI for it to suppress errors
      "activesupport" => "false",
    }.freeze,
    T::Hash[String, String],
  )

  DEFAULT_RBI_MAX_LINE_LENGTH = 120
  DEFAULT_ENVIRONMENT = "development"

  CENTRAL_REPO_ROOT_URI = "https://raw.githubusercontent.com/Shopify/rbi-central/main"
  CENTRAL_REPO_INDEX_PATH = "index.json"
  CENTRAL_REPO_ANNOTATIONS_DIR = "rbi/annotations"
end

require "tapioca/version"

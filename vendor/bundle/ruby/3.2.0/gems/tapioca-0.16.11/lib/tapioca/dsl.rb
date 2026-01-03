# typed: true
# frozen_string_literal: true

require "rbi"
require "spoom"

require "tapioca"
require "tapioca/runtime/reflection"
require "tapioca/helpers/sorbet_helper"
require "tapioca/helpers/rbi_helper"
require "tapioca/rbi_ext/model"
require "tapioca/rbi_formatter"
require "tapioca/dsl/compilers"
require "tapioca/dsl/pipeline"
require "tapioca/dsl/compiler"

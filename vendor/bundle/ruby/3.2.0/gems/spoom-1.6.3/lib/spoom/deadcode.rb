# typed: strict
# frozen_string_literal: true

require "erubi"
require "prism"

require_relative "visitor"
require_relative "location"
require_relative "parse"

require_relative "deadcode/erb"
require_relative "deadcode/index"
require_relative "deadcode/indexer"

require_relative "deadcode/definition"
require_relative "deadcode/send"
require_relative "deadcode/plugins"
require_relative "deadcode/remover"

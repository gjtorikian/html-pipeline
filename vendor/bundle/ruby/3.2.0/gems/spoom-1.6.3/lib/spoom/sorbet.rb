# typed: strict
# frozen_string_literal: true

require "spoom/sorbet/assertions"
require "spoom/sorbet/config"
require "spoom/sorbet/errors"
require "spoom/sorbet/lsp"
require "spoom/sorbet/metrics"
require "spoom/sorbet/sigils"

require "open3"

module Spoom
  module Sorbet
    class Error < Spoom::Error
      class Killed < Error; end
      class Segfault < Error; end

      #: ExecResult
      attr_reader :result

      #: (String message, ExecResult result) -> void
      def initialize(message, result)
        super(message)

        @result = result
      end
    end

    CONFIG_PATH = "sorbet/config"
    GEM_PATH = Gem::Specification.find_by_name("sorbet-static").full_gem_path #: String
    GEM_VERSION = Gem::Specification.find_by_name("sorbet-static-and-runtime").version.to_s #: String
    BIN_PATH = (Pathname.new(GEM_PATH) / "libexec" / "sorbet").to_s #: String

    KILLED_CODE = 137
    SEGFAULT_CODE = 139
  end
end

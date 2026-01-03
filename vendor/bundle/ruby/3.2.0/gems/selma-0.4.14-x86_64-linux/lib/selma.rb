# frozen_string_literal: true

if ENV.fetch("DEBUG", false)
  require "amazing_print"
  require "debug"
end

require_relative "selma/extension"

require_relative "selma/sanitizer"
require_relative "selma/html"
require_relative "selma/rewriter"
require_relative "selma/selector"

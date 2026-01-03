# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rake < Base
        ignore_constants_named("APP_RAKEFILE")
      end
    end
  end
end

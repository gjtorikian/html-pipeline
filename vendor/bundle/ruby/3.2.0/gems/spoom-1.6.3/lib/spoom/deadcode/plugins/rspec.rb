# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class RSpec < Base
        ignore_classes_named(/Spec$/)

        ignore_methods_named(
          "after_setup",
          "after_teardown",
          "before_setup",
          "before_teardown",
        )
      end
    end
  end
end

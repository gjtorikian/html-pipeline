# typed: strict
# frozen_string_literal: true

module Spoom
  class Color < T::Enum
    enums do
      CLEAR           = new("\e[0m")
      BOLD            = new("\e[1m")

      BLACK           = new("\e[30m")
      RED             = new("\e[31m")
      GREEN           = new("\e[32m")
      YELLOW          = new("\e[33m")
      BLUE            = new("\e[34m")
      MAGENTA         = new("\e[35m")
      CYAN            = new("\e[36m")
      WHITE           = new("\e[37m")

      LIGHT_BLACK     = new("\e[90m")
      LIGHT_RED       = new("\e[91m")
      LIGHT_GREEN     = new("\e[92m")
      LIGHT_YELLOW    = new("\e[93m")
      LIGHT_BLUE      = new("\e[94m")
      LIGHT_MAGENTA   = new("\e[95m")
      LIGHT_CYAN      = new("\e[96m")
      LIGHT_WHITE     = new("\e[97m")
    end

    #: -> String
    def ansi_code
      serialize
    end
  end

  module Colorize
    #: (String string, *Color color) -> String
    def set_color(string, *color)
      "#{color.map(&:ansi_code).join}#{string}#{Color::CLEAR.ansi_code}"
    end
  end
end

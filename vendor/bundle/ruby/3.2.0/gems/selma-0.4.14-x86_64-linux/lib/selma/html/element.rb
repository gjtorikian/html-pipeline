# frozen_string_literal: true

module Selma
  class HTML
    class Element
      def available?
        !removed?
      end
    end
  end
end

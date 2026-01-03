# typed: strict
# frozen_string_literal: true

module Spoom
  module LSP
    class Error < Spoom::Error
      class AlreadyOpen < Error; end
      class BadHeaders < Error; end

      class Diagnostics < Error
        #: String
        attr_reader :uri

        #: Array[Diagnostic]
        attr_reader :diagnostics

        class << self
          #: (Hash[untyped, untyped] json) -> Diagnostics
          def from_json(json)
            Diagnostics.new(
              json["uri"],
              json["diagnostics"].map { |d| Diagnostic.from_json(d) },
            )
          end
        end

        #: (String uri, Array[Diagnostic] diagnostics) -> void
        def initialize(uri, diagnostics)
          @uri = uri
          @diagnostics = diagnostics
          super()
        end
      end
    end

    class ResponseError < Error
      #: Integer
      attr_reader :code

      #: Hash[untyped, untyped]
      attr_reader :data

      class << self
        #: (Hash[untyped, untyped] json) -> ResponseError
        def from_json(json)
          ResponseError.new(
            json["code"],
            json["message"],
            json["data"],
          )
        end
      end

      #: (Integer code, String message, Hash[untyped, untyped] data) -> void
      def initialize(code, message, data)
        super(message)
        @code = code
        @data = data
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

module Spoom
  module LSP
    # Base messaging
    # We don't use T::Struct for those so we can subclass them

    # A general message as defined by JSON-RPC.
    #
    # The language server protocol always uses `"2.0"` as the `jsonrpc` version.
    class Message
      #: -> void
      def initialize
        @jsonrpc = "2.0" #: String
      end

      #: -> Hash[untyped, untyped]
      def as_json
        instance_variables.each_with_object({}) do |var, obj|
          val = instance_variable_get(var)
          obj[var.to_s.delete("@")] = val if val
        end
      end

      #: (*untyped args) -> String
      def to_json(*args)
        T.unsafe(as_json).to_json(*args)
      end
    end

    # A request message to describe a request between the client and the server.
    #
    # Every processed request must send a response back to the sender of the request.
    class Request < Message
      #: Integer
      attr_reader :id

      #: Hash[untyped, untyped]
      attr_reader :params

      #: (Integer id, String method, Hash[untyped, untyped] params) -> void
      def initialize(id, method, params)
        super()
        @id = id
        @method = method
        @params = params
      end
    end

    # A notification message.
    #
    # A processed notification message must not send a response back. They work like events.
    class Notification < Message
      #: String
      attr_reader :method

      #: Hash[untyped, untyped]
      attr_reader :params

      #: (String method, Hash[untyped, untyped] params) -> void
      def initialize(method, params)
        super()
        @method = method
        @params = params
      end
    end
  end
end

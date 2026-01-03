# typed: strict
# frozen_string_literal: true

require "open3"
require "json"

require_relative "lsp/base"
require_relative "lsp/structures"
require_relative "lsp/errors"

module Spoom
  module LSP
    class Client
      #: (String sorbet_bin, *String sorbet_args, ?path: String) -> void
      def initialize(sorbet_bin, *sorbet_args, path: ".")
        @id = 0 #: Integer
        @open = false #: bool
        io_in, io_out, io_err, _status = T.unsafe(Open3).popen3(sorbet_bin, *sorbet_args, chdir: path)
        @in = io_in #: IO
        @out = io_out #: IO
        @err = io_err #: IO
      end

      #: -> Integer
      def next_id
        @id += 1
      end

      #: (String json_string) -> void
      def send_raw(json_string)
        @in.puts("Content-Length:#{json_string.length}\r\n\r\n#{json_string}")
      end

      #: (Message message) -> Hash[untyped, untyped]?
      def send(message)
        send_raw(message.to_json)
        read if message.is_a?(Request)
      end

      #: -> String?
      def read_raw
        header = @out.gets

        # Sorbet returned an error and forgot to answer
        raise Error::BadHeaders, "bad response headers" unless header&.match?(/Content-Length: /)

        len = header.slice(::Range.new(16, nil)).to_i
        @out.read(len + 2) # +2 'cause of the final \r\n
      end

      #: -> Hash[untyped, untyped]?
      def read
        raw_string = read_raw
        return unless raw_string

        json = JSON.parse(raw_string)

        # Handle error in the LSP protocol
        raise ResponseError.from_json(json["error"]) if json["error"]

        # Handle typechecking errors
        raise Error::Diagnostics.from_json(json["params"]) if json["method"] == "textDocument/publishDiagnostics"

        json
      end

      # LSP requests

      #: (String workspace_path) -> void
      def open(workspace_path)
        raise Error::AlreadyOpen, "Error: CLI already opened" if @open

        send(Request.new(
          next_id,
          "initialize",
          {
            "rootPath" => workspace_path,
            "rootUri" => "file://#{workspace_path}",
            "capabilities" => {},
          },
        ))
        send(Notification.new("initialized", {}))
        @open = true
      end

      #: (String uri, Integer line, Integer column) -> Hover?
      def hover(uri, line, column)
        json = send(Request.new(
          next_id,
          "textDocument/hover",
          {
            "textDocument" => {
              "uri" => uri,
            },
            "position" => {
              "line" => line,
              "character" => column,
            },
          },
        ))

        return unless json && json["result"]

        Hover.from_json(json["result"])
      end

      #: (String uri, Integer line, Integer column) -> Array[SignatureHelp]
      def signatures(uri, line, column)
        json = send(Request.new(
          next_id,
          "textDocument/signatureHelp",
          {
            "textDocument" => {
              "uri" => uri,
            },
            "position" => {
              "line" => line,
              "character" => column,
            },
          },
        ))

        return [] unless json && json["result"] && json["result"]["signatures"]

        json["result"]["signatures"].map { |loc| SignatureHelp.from_json(loc) }
      end

      #: (String uri, Integer line, Integer column) -> Array[Location]
      def definitions(uri, line, column)
        json = send(Request.new(
          next_id,
          "textDocument/definition",
          {
            "textDocument" => {
              "uri" => uri,
            },
            "position" => {
              "line" => line,
              "character" => column,
            },
          },
        ))

        return [] unless json && json["result"]

        json["result"].map { |loc| Location.from_json(loc) }
      end

      #: (String uri, Integer line, Integer column) -> Array[Location]
      def type_definitions(uri, line, column)
        json = send(Request.new(
          next_id,
          "textDocument/typeDefinition",
          {
            "textDocument" => {
              "uri" => uri,
            },
            "position" => {
              "line" => line,
              "character" => column,
            },
          },
        ))

        return [] unless json && json["result"]

        json["result"].map { |loc| Location.from_json(loc) }
      end

      #: (String uri, Integer line, Integer column, ?bool include_decl) -> Array[Location]
      def references(uri, line, column, include_decl = true)
        json = send(Request.new(
          next_id,
          "textDocument/references",
          {
            "textDocument" => {
              "uri" => uri,
            },
            "position" => {
              "line" => line,
              "character" => column,
            },
            "context" => {
              "includeDeclaration" => include_decl,
            },
          },
        ))

        return [] unless json && json["result"]

        json["result"].map { |loc| Location.from_json(loc) }
      end

      #: (String query) -> Array[DocumentSymbol]
      def symbols(query)
        json = send(Request.new(
          next_id,
          "workspace/symbol",
          {
            "query" => query,
          },
        ))

        return [] unless json && json["result"]

        json["result"].map { |loc| DocumentSymbol.from_json(loc) }
      end

      #: (String uri) -> Array[DocumentSymbol]
      def document_symbols(uri)
        json = send(Request.new(
          next_id,
          "textDocument/documentSymbol",
          {
            "textDocument" => {
              "uri" => uri,
            },
          },
        ))

        return [] unless json && json["result"]

        json["result"].map { |loc| DocumentSymbol.from_json(loc) }
      end

      #: -> void
      def close
        send(Request.new(next_id, "shutdown", {}))
        @in.close
        @out.close
        @err.close
        @open = false
      end
    end
  end
end

# typed: true
# frozen_string_literal: true

require "shellwords"

require_relative "../../sorbet/lsp"

module Spoom
  module Cli
    module Srb
      class LSP < Thor
        include Helper

        desc "list", "List all known symbols"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def list
          run do |client|
            printer = symbol_printer
            Dir["**/*.rb"].each do |file|
              res = client.document_symbols(to_uri(file))
              next if res.empty?

              say("Symbols from `#{file}`:")
              printer.print_objects(res)
            end
          end
        end

        desc "hover", "Request hover information"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def hover(file, line, col)
          run do |client|
            res = client.hover(to_uri(file), line.to_i, col.to_i)
            say("Hovering `#{file}:#{line}:#{col}`:")
            if res
              symbol_printer.print_object(res)
            else
              say("<no data>")
            end
          end
        end

        desc "defs", "List definitions of a symbol"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def defs(file, line, col)
          run do |client|
            res = client.definitions(to_uri(file), line.to_i, col.to_i)
            say("Definitions for `#{file}:#{line}:#{col}`:")
            symbol_printer.print_list(res)
          end
        end

        desc "find", "Find symbols matching a query"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def find(query)
          run do |client|
            res = client.symbols(query).reject { |symbol| symbol.location.uri.start_with?("https") }
            say("Symbols matching `#{query}`:")
            symbol_printer.print_objects(res)
          end
        end

        desc "symbols", "List symbols from a file"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def symbols(file)
          run do |client|
            res = client.document_symbols(to_uri(file))
            say("Symbols from `#{file}`:")
            symbol_printer.print_objects(res)
          end
        end

        desc "refs", "List references to a symbol"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def refs(file, line, col)
          run do |client|
            res = client.references(to_uri(file), line.to_i, col.to_i)
            say("References to `#{file}:#{line}:#{col}`:")
            symbol_printer.print_list(res)
          end
        end

        desc "sigs", "List signatures for a symbol"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def sigs(file, line, col)
          run do |client|
            res = client.signatures(to_uri(file), line.to_i, col.to_i)
            say("Signature for `#{file}:#{line}:#{col}`:")
            symbol_printer.print_list(res)
          end
        end

        desc "types", "Display type of a symbol"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def types(file, line, col)
          run do |client|
            res = client.type_definitions(to_uri(file), line.to_i, col.to_i)
            say("Type for `#{file}:#{line}:#{col}`:")
            symbol_printer.print_list(res)
          end
        end

        no_commands do
          def lsp_client
            context_requiring_sorbet!

            path = exec_path
            client = Spoom::LSP::Client.new(
              Spoom::Sorbet::BIN_PATH,
              "--lsp",
              "--enable-all-experimental-lsp-features",
              "--disable-watchman",
              path: path,
            )
            client.open(File.expand_path(path))
            client
          end

          def symbol_printer
            Spoom::LSP::SymbolPrinter.new(
              indent_level: 2,
              colors: options[:color],
              prefix: "file://#{File.expand_path(exec_path)}",
            )
          end

          def run(&block)
            client = lsp_client
            block.call(client)
          rescue Spoom::LSP::Error::Diagnostics => err
            say_error("Sorbet returned typechecking errors for `#{symbol_printer.clean_uri(err.uri)}`")
            err.diagnostics.each do |d|
              say_error("#{d.message} (#{d.code})", status: "  #{d.range}")
            end
            exit(1)
          rescue Spoom::LSP::Error::BadHeaders => err
            say_error("Sorbet didn't answer correctly (#{err.message})")
            exit(1)
          rescue Spoom::LSP::Error => err
            say_error(err.message)
            exit(1)
          ensure
            begin
              client&.close
            rescue
              # We can't do much if Sorbet refuse to close.
              # We kill the parent process and let the child be killed.
              exit(1)
            end
          end

          def to_uri(path)
            "file://" + File.join(File.expand_path(exec_path), path)
          end
        end
      end
    end
  end
end

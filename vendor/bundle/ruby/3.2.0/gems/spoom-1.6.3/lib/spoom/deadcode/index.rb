# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Index
      class Error < Spoom::Error
        #: (String message, parent: Exception) -> void
        def initialize(message, parent:)
          super(message)
          set_backtrace(parent.backtrace)
        end
      end

      #: Model
      attr_reader :model

      #: Hash[String, Array[Definition]]
      attr_reader :definitions

      #: Hash[String, Array[Model::Reference]]
      attr_reader :references

      #: (Model model) -> void
      def initialize(model)
        @model = model
        @definitions = {} #: Hash[String, Array[Definition]]
        @references = {} #: Hash[String, Array[Model::Reference]]
        @ignored = Set.new #: Set[Model::SymbolDef]
      end

      # Indexing

      #: (String file, ?plugins: Array[Plugins::Base]) -> void
      def index_file(file, plugins: [])
        if file.end_with?(".erb")
          erb = File.read(file)
          index_erb(erb, file: file, plugins: plugins)
        else
          rb = File.read(file)
          index_ruby(rb, file: file, plugins: plugins)
        end
      end

      #: (String erb, file: String, ?plugins: Array[Plugins::Base]) -> void
      def index_erb(erb, file:, plugins: [])
        index_ruby(Deadcode::ERB.new(erb).src, file: file, plugins: plugins)
      end

      #: (String rb, file: String, ?plugins: Array[Plugins::Base]) -> void
      def index_ruby(rb, file:, plugins: [])
        node, comments = Spoom.parse_ruby_with_comments(rb, file: file)

        # Index definitions
        model_builder = Model::Builder.new(@model, file, comments: comments)
        model_builder.visit(node)

        # Index references
        refs_visitor = Model::ReferencesVisitor.new(file)
        refs_visitor.visit(node)
        refs_visitor.references.each do |ref|
          (@references[ref.name] ||= []) << ref
        end

        # Index references and sends
        indexer = Indexer.new(file, self, plugins: plugins)
        indexer.visit(node)
      rescue ParseError => e
        raise e
      rescue => e
        raise Error.new("Error while indexing #{file} (#{e.message})", parent: e)
      end

      #: (Definition definition) -> void
      def define(definition)
        (@definitions[definition.name] ||= []) << definition
      end

      #: (String name, Location location) -> void
      def reference_constant(name, location)
        (@references[name] ||= []) << Model::Reference.constant(name, location)
      end

      #: (String name, Location location) -> void
      def reference_method(name, location)
        (@references[name] ||= []) << Model::Reference.method(name, location)
      end

      #: (Model::SymbolDef symbol_def) -> void
      def ignore(symbol_def)
        @ignored << symbol_def
      end

      #: (Array[Plugins::Base] plugins) -> void
      def apply_plugins!(plugins)
        @model.symbols.each do |_full_name, symbol|
          symbol.definitions.each do |symbol_def|
            case symbol_def
            when Model::Class
              plugins.each { |plugin| plugin.internal_on_define_class(symbol_def) }
            when Model::Module
              plugins.each { |plugin| plugin.internal_on_define_module(symbol_def) }
            when Model::Constant
              plugins.each { |plugin| plugin.internal_on_define_constant(symbol_def) }
            when Model::Method
              plugins.each { |plugin| plugin.internal_on_define_method(symbol_def) }
            when Model::Attr
              plugins.each { |plugin| plugin.internal_on_define_accessor(symbol_def) }
            end
          end
        end
      end

      # Mark all definitions having a reference of the same name as `alive`
      #
      # To be called once all the files have been indexed and all the definitions and references discovered.
      #: -> void
      def finalize!
        @model.symbols.each do |_full_name, symbol|
          symbol.definitions.each do |symbol_def|
            case symbol_def
            when Model::Class
              definition = Definition.new(
                kind: Definition::Kind::Class,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::Module
              definition = Definition.new(
                kind: Definition::Kind::Module,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::Constant
              definition = Definition.new(
                kind: Definition::Kind::Constant,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::Method
              definition = Definition.new(
                kind: Definition::Kind::Method,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::AttrAccessor
              definition = Definition.new(
                kind: Definition::Kind::AttrReader,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)

              definition = Definition.new(
                kind: Definition::Kind::AttrWriter,
                name: "#{symbol.name}=",
                full_name: "#{symbol.full_name}=",
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::AttrReader
              definition = Definition.new(
                kind: Definition::Kind::AttrReader,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::AttrWriter
              definition = Definition.new(
                kind: Definition::Kind::AttrWriter,
                name: "#{symbol.name}=",
                full_name: "#{symbol.full_name}=",
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            end
          end
        end
      end

      # Utils

      #: (String name) -> Array[Definition]
      def definitions_for_name(name)
        @definitions[name] || []
      end

      #: -> Array[Definition]
      def all_definitions
        @definitions.values.flatten
      end

      #: -> Array[Model::Reference]
      def all_references
        @references.values.flatten
      end
    end
  end
end

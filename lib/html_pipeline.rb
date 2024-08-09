# frozen_string_literal: true

require "zeitwerk"
lib_dir = File.join(File.dirname(__dir__), "lib")
lib_html_pipeline_dir = File.join(File.dirname(__dir__), "lib", "html_pipeline")
gem_loader = Zeitwerk::Loader.for_gem
gem_loader.inflector.inflect(
  "html_pipeline" => "HTMLPipeline",
)

gem_loader.ignore(File.join(lib_html_pipeline_dir, "convert_filter"))
gem_loader.ignore(File.join(lib_html_pipeline_dir, "node_filter"))
gem_loader.ignore(File.join(lib_html_pipeline_dir, "text_filter"))
gem_loader.ignore(File.join(lib_dir, "html-pipeline.rb"))
gem_loader.setup

if ENV.fetch("DEBUG", false)
  require "amazing_print"
  require "debug"
end

class HTMLPipeline
  # HTML processing filters and utilities. This module includes a small
  # framework for defining DOM based content filters and applying them to user
  # provided content.
  #
  # See HTMLPipeline::Filter for information on building filters.
  #
  # Construct a Pipeline for running multiple HTML filters.  A pipeline is created once
  # with one to many filters, and it then can be `call`ed many times over the course
  # of its lifetime with input.
  #
  # filters         - Array of Filter objects. Each must respond to call(doc,
  #                   context). Filters are performed in the order provided.
  # default_context - The default context hash. Values specified here will be merged
  #                   into values from the each individual pipeline run.  Can NOT be
  #                   nil.  Default: empty Hash.
  # result_class    - The default Class of the result object for individual
  #                   calls.  Default: Hash.  Protip:  Pass in a Struct to get
  #                   some semblance of type safety.
  class MissingDependencyError < RuntimeError; end
  class InvalidFilterError < ArgumentError; end

  class << self
    def optional_dependency(name, requirer)
      require name
    rescue LoadError # rubocop:disable Lint/SuppressedException:
    end

    def require_dependency(name, requirer)
      require name
    rescue LoadError => e
      raise MissingDependencyError,
        "Missing dependency '#{name}' for #{requirer}. See README.md for details.\n#{e.class.name}: #{e}"
    end

    def require_dependencies(names, requirer)
      dependency_list = names.dup
      loaded = false

      while !loaded && names.length > 1
        name = names.shift

        begin
          require_dependency(name, requirer)
          loaded = true # we got a dependency
          define_dependency_loaded_method(name, true)
        # try the next dependency
        rescue MissingDependencyError
          define_dependency_loaded_method(name, false)
        end
      end

      return if loaded

      begin
        name = names.shift
        require name
        define_dependency_loaded_method(name, true)
      rescue LoadError => e
        raise MissingDependencyError,
          "Missing all dependencies '#{dependency_list.join(", ")}' for #{requirer}. See README.md for details.\n#{e.class.name}: #{e}"
      end
    end

    def define_dependency_loaded_method(name, value)
      self.class.define_method(:"#{name}_loaded?", -> { value })
    end
  end
  # Public: Returns an Array of Filter objects for this Pipeline.
  attr_reader :text_filters, :node_filters

  # Public: A hash representing the sanitization configuration settings
  attr_reader :sanitization_config

  # Public: Instrumentation service for the pipeline.
  # Set an ActiveSupport::Notifications compatible object to enable.
  attr_accessor :instrumentation_service

  # Public: String name for this Pipeline. Defaults to Class name.
  attr_writer :instrumentation_name

  def instrumentation_name
    return @instrumentation_name if defined?(@instrumentation_name)

    @instrumentation_name = self.class.name
  end

  class << self
    # Public: Default instrumentation service for new pipeline objects.
    attr_accessor :default_instrumentation_service
  end

  def initialize(text_filters: [], convert_filter: nil, sanitization_config: SanitizationFilter::DEFAULT_CONFIG, node_filters: [], default_context: {}, result_class: Hash)
    raise ArgumentError, "default_context cannot be nil" if default_context.nil?

    @text_filters = text_filters.flatten.freeze || []
    validate_filters(@text_filters, HTMLPipeline::TextFilter)

    @node_filters = node_filters.flatten.freeze || []
    validate_filters(@node_filters, HTMLPipeline::NodeFilter)

    @convert_filter = convert_filter

    if @convert_filter.nil? && (!@text_filters.empty? && !@node_filters.empty?)
      raise InvalidFilterError, "Must provide `convert_filter` if `text_filters` and `node_filters` are also provided"
    elsif !@convert_filter.nil?
      validate_filter(@convert_filter, HTMLPipeline::ConvertFilter)
    end

    @sanitization_config = sanitization_config.nil? ? nil : Selma::Sanitizer.new(sanitization_config)

    @default_context = default_context.freeze
    @instrumentation_service = self.class.default_instrumentation_service
  end

  # Apply all filters in the pipeline to the given HTML.
  #
  # html    - A UTF-8 String comprised of HTML.
  # context - The context hash passed to each filter. See the Filter docs
  #           for more info on possible values. This object MUST NOT be modified
  #           in place by filters.  Use the Result for passing state back.
  # result  - The result Hash passed to each filter for modification.  This
  #           is where Filters store extracted information from the content.
  #
  # Returns the result Hash after being filtered by this Pipeline.  Contains an
  # :output key with the String HTML markup based on the
  # output of the last filter in the pipeline.
  def call(text, context: {}, result: {})
    context = @default_context.merge(context)
    context = context.freeze
    result ||= {}

    if @text_filters.any?
      payload = default_payload({
        text_filters: @text_filters.map { |f| f.class.name },
        context: context,
        result: result,
      })
      instrument("call_text_filters.html_pipeline", payload) do
        result[:output] =
          @text_filters.inject(text) do |doc, filter|
            perform_filter(filter, doc, context: (filter.context || {}).merge(context), result: result)
          end
      end
    end

    text = result[:output] || text

    html = if @convert_filter.nil?
      text
    else
      instrument("call_convert_filter.html_pipeline", payload) do
        html = @convert_filter.call(text, context: (@convert_filter.context || {}).merge(context))
      end
    end

    rewriter_options = {
      memory: {
        max_allowed_memory_usage: 5242880, # arbitrary limit of 5MB
      },
    }

    if @node_filters.empty?
      instrument("sanitization.html_pipeline", payload) do
        result[:output] = Selma::Rewriter.new(sanitizer: @sanitization_config, options: rewriter_options).rewrite(html)
      end
    else
      instrument("call_node_filters.html_pipeline", payload) do
        @node_filters.each { |filter| filter.context = (filter.context || {}).merge(context) }
        result[:output] = Selma::Rewriter.new(sanitizer: @sanitization_config, handlers: @node_filters, options: rewriter_options).rewrite(html)
        payload = default_payload({
          node_filters: @node_filters.map { |f| f.class.name },
          context: context,
          result: result,
        })
      end
    end

    result = result.merge(@node_filters.collect(&:result).reduce({}, :merge))
    @node_filters.each(&:reset!)

    result
  end

  # Internal: Applies a specific filter to the supplied doc.
  #
  # The filter is instrumented.
  #
  # Returns the result of the filter.
  def perform_filter(filter, doc, context: {}, result: {})
    payload = default_payload({
      filter: filter.class.name,
      context: context,
      result: result,
    })

    instrument("call_filter.html_pipeline", payload) do
      filter.call(doc, context: context, result: result)
    end
  end

  # Like call but guarantee the value returned is a string of HTML markup.
  def to_html(input, context: {}, result: {})
    result = call(input, context: context, result: result)
    output = result[:output]
    if output.respond_to?(:to_html)
      output.to_html
    else
      output.to_s
    end
  end

  # Public: setup instrumentation for this pipeline.
  #
  # Returns nothing.
  def setup_instrumentation(name, service: nil)
    self.instrumentation_name = name
    self.instrumentation_service =
      service || self.class.default_instrumentation_service
  end

  # Internal: if the `instrumentation_service` object is set, instruments the
  # block, otherwise the block is ran without instrumentation.
  #
  # Returns the result of the provided block.
  def instrument(event, payload = {}, &block)
    payload ||= default_payload
    return yield(payload) unless instrumentation_service

    instrumentation_service.instrument(event, payload, &block)
  end

  # Internal: Default payload for instrumentation.
  #
  # Accepts a Hash of additional payload data to be merged.
  #
  # Returns a Hash.
  def default_payload(payload = {})
    { pipeline: instrumentation_name }.merge(payload)
  end

  private def validate_filter(filter, klass)
    unless correctly_ancestored?(filter, klass)
      raise InvalidFilterError, "Filter must inherit from `#{klass}`; #{filter} does not"
    end
  end

  private def validate_filters(filters, klass)
    return if filters.nil? || filters.empty?

    invalid_filters = filters.reject { |f| correctly_ancestored?(f, klass) }

    unless invalid_filters.empty?
      verb = invalid_filters.count == 1 ? "does" : "do"
      raise InvalidFilterError, "All filters must inherit from `#{klass}`; #{invalid_filters.join(", ")} #{verb} not"
    end
  end

  private def correctly_ancestored?(filter, klass)
    if filter.respond_to?(:ancestors)
      filter.ancestors.include?(klass)
    else
      filter.class.ancestors.include?(klass)
    end
  end
end

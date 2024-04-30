# frozen_string_literal: true

class HTMLPipeline
  # Base class for user content HTML filters. Each filter takes an
  # HTML string, performs modifications on it, and/or writes information to a result hash.
  # Filters must return a String with HTML markup.
  #
  # The `context` Hash passes options to filters and should not be changed in
  # place. A `result` Hash allows filters to make extracted information
  # available to the caller, and is mutable.
  #
  # Common context options:
  #   :base_url   - The site's base URL
  #   :repository - A Repository providing context for the HTML being processed
  #
  # Each filter may define additional options and output values. See the class
  # docs for more info.
  class Filter
    class InvalidDocumentException < StandardError; end

    def initialize(context: {}, result: {})
      @context = context
      @result = result
      validate
    end

    # Public: Returns a simple Hash used to pass extra information into filters
    # and also to allow filters to make extracted information available to the
    # caller.
    attr_accessor :context

    # Public: Returns a Hash used to allow filters to pass back information
    # to callers of the various Pipelines.  This can be used for
    # #mentioned_users, for example.
    attr_reader :result

    # The main filter entry point. The doc attribute is guaranteed to be a
    # string when invoked. Subclasses should modify
    # this text in place or extract information and add it to the context
    # hash.
    def call
      raise NoMethodError
    end

    class << self
      # Perform a filter on doc with the given context.
      #
      # Returns a String comprised of HTML markup.
      def call(input, context: {})
        raise NoMethodError
      end
    end
    # Make sure the context has everything we need. Noop: Subclasses can override.
    def validate; end

    # The site's base URL provided in the context hash, or '/' when no
    # base URL was specified.
    def base_url
      context[:base_url] || "/"
    end

    # Helper method for filter subclasses used to determine if any of a node's
    # ancestors have one of the tag names specified.
    #
    # node - The Node object to check.
    # tags - An array of tag name strings to check. These should be downcase.
    #
    # Returns true when the node has a matching ancestor.
    def has_ancestor?(element, ancestor)
      ancestors = element.ancestors
      ancestors.include?(ancestor)
    end

    # Validator for required context. This will check that anything passed in
    # contexts exists in @contexts
    #
    # If any errors are found an ArgumentError will be raised with a
    # message listing all the missing contexts and the filters that
    # require them.
    def needs(*keys)
      missing = keys.reject { |key| context.include?(key) }

      return if missing.none?

      raise ArgumentError,
        "Missing context keys for #{self.class.name}: #{missing.map(&:inspect).join(", ")}"
    end
  end
end

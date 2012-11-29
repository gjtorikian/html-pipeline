require 'singleton'

module HTML
  class Pipeline
    # Singleton for tracking required context. 
    # Required context can be pushed onto the internal @required_context Hash.
    # For example:
    #
    #   ValidateContext.instance['HTML::Pipeline::CamoFilter'] = [:asset_host]
    #
    # The key needs to be the name of the class that requires the context
    # specified as an array of symbols
    class ValidateContext
      include Singleton
   
      def initialize
        @required_context ||= {}
      end
  
      def required_context
        @required_context
      end
      
      def [](key)
        @required_context[key]
      end

      def []=(key, value)
        @required_context[key] = value
      end
    end
  end
end
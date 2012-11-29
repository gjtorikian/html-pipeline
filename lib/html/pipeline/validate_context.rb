require 'singleton'

module HTML
  class Pipeline
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
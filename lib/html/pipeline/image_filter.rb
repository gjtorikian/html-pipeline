module HTML
  class Pipeline
    class ImageFilter < TextFilter
      def call
        @text.gsub(/(https|http)?:\/\/.+\.(jpg|jpeg|bmp|gif|png)(\?\S+)?/i) do |match|
        %|<img src="#{match}" alt=""/>|
        end
      end
    end
  end
end

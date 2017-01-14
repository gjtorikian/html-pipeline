module HTML
  class Pipeline
    # HTML filter that rewrites 'target' attribute to all anchors in a document.
    # Useful for causing to open in a new tab (set target to '_blank').
    #
    # Context options:
    #   :target - The target to be added to <a>, defaults to TARGET ('_default')
    #             Set to 'false' to remove targets
    #
    class AnchorTargetFilter < Filter
      TARGET = '_default'

      def call
        doc.css('a').each do |element|
          if target == false
            element.attributes['target'].remove
          else
            element.set_attribute('target', target)
          end
        end
        doc
      end

      # if target is nil, replace with default TARGET
      # if target is false, remove target
      def target
        case context[:target]
        when false
          false
        when nil
          TARGET
        else
          context[:target]
        end
      end
    end
  end
end

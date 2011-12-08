module GitHub::HTML
  # This filter rewrites image tags with a max-width inline style.
  # Its used for our HTML emails which don't use stylesheets.
  class ImageMaxWidthFilter < Filter
    def call
      doc.search('img').each do |element|
        # Skip if theres already a style attribute. Not sure how this
        # would happen but we can reconsider it in the future.
        next if element['style']

        element['style'] = "max-width:100%;"
      end
      doc
    end
  end
end

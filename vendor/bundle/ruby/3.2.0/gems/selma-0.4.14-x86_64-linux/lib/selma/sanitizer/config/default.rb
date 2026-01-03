# frozen_string_literal: true

module Selma
  class Sanitizer
    module Config
      # although there are many more protocol types, eg., ftp, xmpp, etc.,
      # these are the only ones that are allowed by default
      VALID_PROTOCOLS = ["http", "https", "mailto", :relative]

      DEFAULT = freeze_config(
        # Whether or not to allow HTML comments. Allowing comments is strongly
        # discouraged, since IE allows script execution within conditional
        # comments.
        allow_comments: false,

        # Whether or not to allow well-formed HTML doctype declarations such as
        # "<!DOCTYPE html>" when sanitizing a document.
        allow_doctype: false,

        # HTML attributes to allow in specific elements. By default, no attributes
        # are allowed. Use the symbol :data to indicate that arbitrary HTML5
        # data-* attributes should be allowed.
        attributes: {},

        # HTML elements to allow. By default, no elements are allowed (which means
        # that all HTML will be stripped).
        elements: [],

        # URL handling protocols to allow in specific attributes. By default, no
        # protocols are allowed. Use :relative in place of a protocol if you want
        # to allow relative URLs sans protocol. Set to `:all` to allow any protocol.
        protocols: {},

        # An Array of element names whose contents will be removed. The contents
        # of all other filtered elements will be left behind.
        remove_contents: [
          "iframe",
          "math",
          "noembed",
          "noframes",
          "noscript",
          "plaintext",
          "script",
          "style",
          "svg",
          "xmp",
        ],

        # Elements which, when removed, should have their contents surrounded by
        # whitespace.
        whitespace_elements: [
          "address",
          "article",
          "aside",
          "blockquote",
          "br",
          "dd",
          "div",
          "dl",
          "dt",
          "footer",
          "h1",
          "h2",
          "h3",
          "h4",
          "h5",
          "h6",
          "header",
          "hgroup",
          "hr",
          "li",
          "nav",
          "ol",
          "p",
          "pre",
          "section",
          "ul",
        ],
      )
    end
  end
end

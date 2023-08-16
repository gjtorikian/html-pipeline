# frozen_string_literal: true

require "test_helper"
require "html_pipeline/node_filter/https_filter"

HttpsFilter = HTMLPipeline::NodeFilter::HttpsFilter

class HTMLPipeline
  class HttpsFilterTest < Minitest::Test
    def setup
      @options = { base_url: "http://github.com" }
    end

    def test_http
      assert_equal(
        %(<a href="https://github.com">github.com</a>),
        HttpsFilter.call(%(<a href="http://github.com">github.com</a>), context: @options),
      )
    end

    def test_https
      assert_equal(
        %(<a href="https://github.com">github.com</a>),
        HttpsFilter.call(%(<a href="https://github.com">github.com</a>), context: @options),
      )
    end

    def test_subdomain
      assert_equal(
        %(<a href="https://help.github.com">github.com</a>),
        HttpsFilter.call(%(<a href="http://help.github.com">github.com</a>), context: @options),
      )
    end

    def test_other
      assert_equal(
        %(<a href="https://github.io">github.io</a>),
        HttpsFilter.call(%(<a href="http://github.io">github.io</a>), context: @options),
      )
    end
  end
end

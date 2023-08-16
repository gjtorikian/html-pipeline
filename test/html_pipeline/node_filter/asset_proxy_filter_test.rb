# frozen_string_literal: true

require "test_helper"
require "html_pipeline/node_filter/asset_proxy_filter"

class HTMLPipeline
  class AssetProxyFilterTest < Minitest::Spec
    DESCRIBED_CLASS = HTMLPipeline::NodeFilter::AssetProxyFilter

    def setup
      @filter = DESCRIBED_CLASS
    end

    def image(path)
      %(<img src="#{path}" />)
    end

    describe "setting up the context" do
      it "#transform_context" do
        settings = {
          enabled: true,
          secret_key: "shared-secret",
          url: "https://assets.example.com",
          allowlist: ["somewhere.com", "*.mydomain.com"],
        }

        context = DESCRIBED_CLASS.transform_context({}, settings)

        assert_equal("shared-secret", context[:asset_proxy_secret_key])
        assert_equal("https://assets.example.com", context[:asset_proxy])
        assert_equal(/^(somewhere\.com|.*?\.mydomain\.com)$/i, context[:asset_proxy_domain_regexp])
      end

      it "requires :asset_proxy" do
        settings = { enabled: true }
        context = DESCRIBED_CLASS.transform_context({}, settings)

        exception = assert_raises(ArgumentError) do
          @filter.call("", context: context)
        end

        assert_match(/:asset_proxy/, exception.message)
      end

      it "requires :asset_proxy_secret_key" do
        settings = { enabled: true, url: "example.com" }
        context = DESCRIBED_CLASS.transform_context({}, settings)

        exception = assert_raises(ArgumentError) do
          @filter.call("", context: context)
        end

        assert_match(/:asset_proxy_secret_key/, exception.message)
      end
    end

    describe "when properly configured" do
      before do
        settings = {
          enabled: true,
          secret_key: "shared-secret",
          url: "https://assets.mydomain.com",
          allowlist: ["somewhere.com", "*.mydomain.com"],
        }

        @context = DESCRIBED_CLASS.transform_context({}, settings)
      end

      it "replaces img src" do
        src = "http://example.com/test.png"
        new_image = '<img src="https://assets.mydomain.com/08df250eeeef1a8cf2c761475ac74c5065105612/687474703a2f2f6578616d706c652e636f6d2f746573742e706e67" data-canonical-src="http://example.com/test.png" />'
        res = @filter.call(image(src), context: @context)

        assert_equal(new_image, res)
      end

      it "replaces invalid URLs" do
        src = "///example.com/test.png"
        new_image = '<img src="https://assets.mydomain.com/3368d2c7b9bed775bdd1e811f36a4b80a0dcd8ab/2f2f2f6578616d706c652e636f6d2f746573742e706e67" data-canonical-src="///example.com/test.png" />'
        res = @filter.call(image(src), context: @context)

        assert_equal(new_image, res)
      end

      it "skips internal images" do
        src = "http://images.mydomain.com/test.png"
        res = @filter.call(image(src), context: @context)

        assert_equal(image(src), res)
      end

      it "skip relative urls" do
        src = "/test.png"
        res = @filter.call(image(src), context: @context)

        assert_equal(image(src), res)
      end

      it "skips single domain" do
        src = "http://somewhere.com/test.png"
        res = @filter.call(image(src), context: @context)

        assert_equal(image(src), res)
      end

      it "skips single domain and ignores url in query string" do
        src = "http://somewhere.com/test.png?url=http://example.com/test.png"
        res = @filter.call(image(src), context: @context)

        assert_equal(image(src), res)
      end

      it "skips wildcarded domain" do
        src = "http://images.mydomain.com/test.png"
        res = @filter.call(image(src), context: @context)

        assert_equal(image(src), res)
      end
    end
  end
end

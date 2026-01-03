# typed: true
# frozen_string_literal: true

module Tapioca
  module EnvHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Thor }

    sig { params(options: T::Hash[Symbol, T.untyped]).void }
    def set_environment(options) # rubocop:disable Naming/AccessorMethodName
      ENV["RAILS_ENV"] = ENV["RACK_ENV"] = options[:environment]
      ENV["RUBY_DEBUG_LAZY"] = "1"
    end
  end
end

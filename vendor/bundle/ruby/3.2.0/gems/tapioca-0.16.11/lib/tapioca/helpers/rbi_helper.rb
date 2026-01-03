# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBIHelper
    extend T::Sig
    include SorbetHelper
    extend SorbetHelper
    extend self

    class << self
      extend T::Sig

      sig do
        params(
          type: String,
          variance: Symbol,
          fixed: T.nilable(String),
          upper: T.nilable(String),
          lower: T.nilable(String),
        ).returns(String)
      end
      def serialize_type_variable(type, variance, fixed, upper, lower)
        variance = nil if variance == :invariant

        block = []
        block << "fixed: #{fixed}" if fixed
        block << "lower: #{lower}" if lower
        block << "upper: #{upper}" if upper

        parameters = []
        parameters << ":#{variance}" if variance

        serialized = type.dup
        serialized << "(#{parameters.join(", ")})" unless parameters.empty?
        serialized << " { { #{block.join(", ")} } }" unless block.empty?
        serialized
      end
    end

    sig { params(name: String, type: String).returns(RBI::TypedParam) }
    def create_param(name, type:)
      create_typed_param(RBI::ReqParam.new(name), type)
    end

    sig { params(name: String, type: String, default: String).returns(RBI::TypedParam) }
    def create_opt_param(name, type:, default:)
      create_typed_param(RBI::OptParam.new(name, default), type)
    end

    sig { params(name: String, type: String).returns(RBI::TypedParam) }
    def create_rest_param(name, type:)
      create_typed_param(RBI::RestParam.new(name), type)
    end

    sig { params(name: String, type: String).returns(RBI::TypedParam) }
    def create_kw_param(name, type:)
      create_typed_param(RBI::KwParam.new(name), type)
    end

    sig { params(name: String, type: String, default: String).returns(RBI::TypedParam) }
    def create_kw_opt_param(name, type:, default:)
      create_typed_param(RBI::KwOptParam.new(name, default), type)
    end

    sig { params(name: String, type: String).returns(RBI::TypedParam) }
    def create_kw_rest_param(name, type:)
      create_typed_param(RBI::KwRestParam.new(name), type)
    end

    sig { params(name: String, type: String).returns(RBI::TypedParam) }
    def create_block_param(name, type:)
      create_typed_param(RBI::BlockParam.new(name), type)
    end

    sig { params(param: RBI::Param, type: String).returns(RBI::TypedParam) }
    def create_typed_param(param, type)
      RBI::TypedParam.new(param: param, type: sanitize_signature_types(type))
    end

    sig { params(sig_string: String).returns(String) }
    def sanitize_signature_types(sig_string)
      sig_string
        .gsub(".returns(<VOID>)", ".void")
        .gsub("<VOID>", "void")
        .gsub("<NOT-TYPED>", "T.untyped")
        .gsub(".params()", "")
    end

    sig { params(type: String).returns(String) }
    def as_nilable_type(type)
      if type.start_with?("T.nilable(", "::T.nilable(") || type == "T.untyped" || type == "::T.untyped"
        type
      else
        "T.nilable(#{type})"
      end
    end

    sig { params(type: String).returns(String) }
    def as_non_nilable_type(type)
      if type.match(/\A(?:::)?T.nilable\((.+)\)\z/)
        T.must(::Regexp.last_match(1))
      else
        type
      end
    end

    sig { params(name: String).returns(T::Boolean) }
    def valid_method_name?(name)
      Prism.parse_success?("def self.#{name}(a); end")
    end

    sig { params(name: String).returns(T::Boolean) }
    def valid_parameter_name?(name)
      Prism.parse_success?("def sentinel_method_name(#{name}:); end")
    end
  end
end

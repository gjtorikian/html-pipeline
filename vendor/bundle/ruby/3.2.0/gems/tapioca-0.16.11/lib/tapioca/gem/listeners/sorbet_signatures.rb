# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetSignatures < Base
        extend T::Sig

        include Runtime::Reflection
        include RBIHelper

        TYPE_PARAMETER_MATCHER = /T\.type_parameter\(:?([[:word:]]+)\)/

        private

        sig { override.params(event: MethodNodeAdded).void }
        def on_method(event)
          signature = event.signature
          return unless signature

          event.node.sigs << compile_signature(signature, event.parameters)
        end

        sig { params(signature: T.untyped, parameters: T::Array[[Symbol, String]]).returns(RBI::Sig) }
        def compile_signature(signature, parameters)
          parameter_types = T.let(signature.arg_types.to_h, T::Hash[Symbol, T::Types::Base])
          parameter_types.merge!(signature.kwarg_types)
          parameter_types[signature.rest_name] = signature.rest_type if signature.has_rest
          parameter_types[signature.keyrest_name] = signature.keyrest_type if signature.has_keyrest
          parameter_types[signature.block_name] = signature.block_type if signature.block_name

          sig = RBI::Sig.new

          parameters.each do |_, name|
            type = sanitize_signature_types(parameter_types[name.to_sym].to_s)
            @pipeline.push_symbol(type)
            sig << RBI::SigParam.new(name, type)
          end

          return_type = name_of_type(signature.return_type)
          return_type = sanitize_signature_types(return_type)
          sig.return_type = return_type
          @pipeline.push_symbol(return_type)

          parameter_types.values.join(", ").scan(TYPE_PARAMETER_MATCHER).flatten.uniq.each do |k, _|
            sig.type_params << k
          end

          case signature.mode
          when "abstract"
            sig.is_abstract = true
          when "override"
            sig.is_override = true
          when "overridable_override"
            sig.is_overridable = true
            sig.is_override = true
          when "overridable"
            sig.is_overridable = true
          end

          sig.is_final = signature_final?(signature)

          sig
        end

        sig { params(signature: T.untyped).returns(T::Boolean) }
        def signature_final?(signature)
          modules_with_final = T::Private::Methods.instance_variable_get(:@modules_with_final)
          # In https://github.com/sorbet/sorbet/pull/7531, Sorbet changed internal hashes to be compared by identity,
          # starting on version 0.5.11155
          final_methods = modules_with_final[signature.owner] || modules_with_final[signature.owner.object_id]
          return false unless final_methods

          final_methods.include?(signature.method_name)
        end

        sig { override.params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end

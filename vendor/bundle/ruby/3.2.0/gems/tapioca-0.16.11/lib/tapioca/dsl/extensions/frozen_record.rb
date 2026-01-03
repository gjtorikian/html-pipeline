# typed: true
# frozen_string_literal: true

begin
  require "active_support"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      module Extensions
        module FrozenRecord
          attr_reader :__tapioca_scope_names

          def scope(name, body)
            @__tapioca_scope_names ||= []
            @__tapioca_scope_names << name

            super
          end

          ::ActiveSupport.on_load(:before_configuration) do
            next unless defined?(::FrozenRecord::Base)

            ::FrozenRecord::Base.singleton_class.prepend(::Tapioca::Dsl::Compilers::Extensions::FrozenRecord)
          end
        end
      end
    end
  end
end

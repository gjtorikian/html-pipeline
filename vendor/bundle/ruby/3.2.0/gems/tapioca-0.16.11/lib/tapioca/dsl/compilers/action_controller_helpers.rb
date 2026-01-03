# typed: strict
# frozen_string_literal: true

return unless defined?(ActionController::Base)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActionControllerHelpers` decorates RBI files for all
      # subclasses of [`ActionController::Base`](https://api.rubyonrails.org/classes/ActionController/Helpers.html).
      #
      # For example, with the following `MyHelper` module:
      #
      # ~~~rb
      # module MyHelper
      #   def greet(user)
      #     # ...
      #   end
      #
      #  def localized_time
      #     # ...
      #   end
      # end
      # ~~~
      #
      # and the following controller:
      #
      # ~~~rb
      # class UserController < ActionController::Base
      #   helper MyHelper
      #   helper { def age(user) "99" end }
      #   helper_method :current_user_name
      #
      #   def current_user_name
      #     # ...
      #   end
      # end
      # ~~~
      #
      # this compiler will produce an RBI file `user_controller.rbi` with the following content:
      #
      # ~~~rbi
      # # user_controller.rbi
      # # typed: strong
      # class UserController
      #   module HelperMethods
      #     include MyHelper
      #
      #     sig { params(user: T.untyped).returns(T.untyped) }
      #     def age(user); end
      #
      #     sig { returns(T.untyped) }
      #     def current_user_name; end
      #   end
      #
      #   class HelperProxy < ::ActionView::Base
      #     include HelperMethods
      #   end
      #
      #   sig { returns(HelperProxy) }
      #   def helpers; end
      # end
      # ~~~
      class ActionControllerHelpers < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ActionController::Base) } }

        sig { override.void }
        def decorate
          helpers_module = constant._helpers
          proxied_helper_methods = constant._helper_methods.map(&:to_s).map(&:to_sym)

          helper_proxy_name = "HelperProxy"
          helper_methods_name = "HelperMethods"

          # Define the helpers method
          root.create_path(constant) do |controller|
            controller.create_method("helpers", return_type: helper_proxy_name)

            # Create helper method module
            controller.create_module(helper_methods_name) do |helper_methods|
              # If the controller has no helper defined, then it just inherits
              # the Action Controller base helper methods module, so we should
              # just add that as an include and stop doing more processing.
              if helpers_module.name == "ActionController::Base::HelperMethods"
                next helper_methods.create_include(T.must(qualified_name_of(helpers_module)))
              end

              # Find all the included helper modules and generate an include
              # for each of those helper modules
              gather_includes(helpers_module).each do |ancestor|
                helper_methods.create_include(ancestor)
              end

              # Generate a method definition in the helper module for each
              # helper method defined via the `helper_method` call in the controller.
              helpers_module.instance_methods(false).each do |method_name|
                method = if proxied_helper_methods.include?(method_name)
                  helper_method_proxy_target(method_name)
                else
                  helpers_module.instance_method(method_name)
                end

                if method
                  create_method_from_def(helper_methods, method)
                else
                  create_unknown_proxy_method(helper_methods, method_name)
                end
              end
            end

            # Create helper proxy class
            controller.create_class(helper_proxy_name, superclass_name: "::ActionView::Base") do |proxy|
              proxy.create_include(helper_methods_name)
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActionController::Base).select(&:name).select do |klass|
              klass.const_defined?(:HelperMethods, false)
            end
          end
        end

        private

        sig { params(method_name: Symbol).returns(T.nilable(UnboundMethod)) }
        def helper_method_proxy_target(method_name)
          # Lookup the proxy target method only if it is defined as a public/protected or private method.
          if constant.method_defined?(method_name) || constant.private_method_defined?(method_name)
            constant.instance_method(method_name)
          end
        end

        sig { params(helper_methods: RBI::Scope, method_name: Symbol).void }
        def create_unknown_proxy_method(helper_methods, method_name)
          helper_methods.create_method(
            method_name.to_s,
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_kw_rest_param("kwargs", type: "T.untyped"),
              create_block_param("blk", type: "T.untyped"),
            ],
            return_type: "T.untyped",
          )
        end

        sig { params(mod: Module).returns(T::Array[String]) }
        def gather_includes(mod)
          mod.ancestors
            .reject { |ancestor| ancestor.is_a?(Class) || ancestor == mod || name_of(ancestor).nil? }
            .map { |ancestor| T.must(qualified_name_of(ancestor)) }
            .reverse
        end
      end
    end
  end
end

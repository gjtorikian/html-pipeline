# typed: strict
# frozen_string_literal: true

module Tapioca
  module Runtime
    class DynamicMixinCompiler
      extend T::Sig
      include Runtime::Reflection

      sig { returns(T::Array[Module]) }
      attr_reader :dynamic_extends, :dynamic_includes

      sig { returns(T::Array[Symbol]) }
      attr_reader :class_attribute_readers, :class_attribute_writers, :class_attribute_predicates

      sig { returns(T::Array[Symbol]) }
      attr_reader :instance_attribute_readers, :instance_attribute_writers, :instance_attribute_predicates

      sig { params(constant: Module).void }
      def initialize(constant)
        @constant = constant
        mixins_from_modules = {}.compare_by_identity
        class_attribute_readers = T.let([], T::Array[Symbol])
        class_attribute_writers = T.let([], T::Array[Symbol])
        class_attribute_predicates = T.let([], T::Array[Symbol])

        instance_attribute_readers = T.let([], T::Array[Symbol])
        instance_attribute_writers = T.let([], T::Array[Symbol])
        instance_attribute_predicates = T.let([], T::Array[Symbol])

        Class.new do
          # Override the `self.include` method
          define_singleton_method(:include) do |mod|
            # Take a snapshot of the list of singleton class ancestors
            # before the actual include
            before = singleton_class.ancestors
            # Call the actual `include` method with the supplied module
            ::Tapioca::Runtime::Trackers::Mixin.with_disabled_registration do
              super(mod).tap do
                # Take a snapshot of the list of singleton class ancestors
                # after the actual include
                after = singleton_class.ancestors
                # The difference is the modules that are added to the list
                # of ancestors of the singleton class. Those are all the
                # modules that were `extend`ed due to the `include` call.
                #
                # We record those modules on our lookup table keyed by
                # the included module with the values being all the modules
                # that that module pulls into the singleton class.
                #
                # We need to reverse the order, since the extend order should
                # be the inverse of the ancestor order. That is, earlier
                # extended modules would be later in the ancestor chain.
                mixins_from_modules[mod] = (after - before).reverse!
              end
            end
          rescue Exception # rubocop:disable Lint/RescueException
            # this is a best effort, bail if we can't perform this
          end

          define_singleton_method(:class_attribute) do |*attrs, **kwargs|
            class_attribute_readers.concat(attrs)
            class_attribute_writers.concat(attrs)

            instance_predicate = kwargs.fetch(:instance_predicate, true)
            instance_accessor = kwargs.fetch(:instance_accessor, true)
            instance_reader = kwargs.fetch(:instance_reader, instance_accessor)
            instance_writer = kwargs.fetch(:instance_writer, instance_accessor)

            if instance_reader
              instance_attribute_readers.concat(attrs)
            end

            if instance_writer
              instance_attribute_writers.concat(attrs)
            end

            if instance_predicate
              class_attribute_predicates.concat(attrs)

              if instance_reader
                instance_attribute_predicates.concat(attrs)
              end
            end

            super(*attrs, **kwargs) if defined?(super)
          end

          # rubocop:disable Style/MissingRespondToMissing
          T::Sig::WithoutRuntime.sig { params(symbol: Symbol, args: T.untyped).returns(T.untyped) }
          def method_missing(symbol, *args)
            # We need this here so that we can handle any random instance
            # method calls on the fake including class that may be done by
            # the included module during the `self.included` hook.
          end

          class << self
            extend T::Sig

            T::Sig::WithoutRuntime.sig { params(symbol: Symbol, args: T.untyped).returns(T.untyped) }
            def method_missing(symbol, *args)
              # Similarly, we need this here so that we can handle any
              # random class method calls on the fake including class
              # that may be done by the included module during the
              # `self.included` hook.
            end
          end
          # rubocop:enable Style/MissingRespondToMissing
        end.include(constant)

        # The value that corresponds to the original included constant
        # is the list of all dynamically extended modules because of that
        # constant. We grab that value by deleting the key for the original
        # constant.
        @dynamic_extends = T.let(mixins_from_modules.delete(constant) || [], T::Array[Module])

        # Since we deleted the original constant from the list of keys, all
        # the keys that remain are the ones that are dynamically included modules
        # during the include of the original constant.
        @dynamic_includes = T.let(mixins_from_modules.keys, T::Array[Module])

        @class_attribute_readers = T.let(class_attribute_readers, T::Array[Symbol])
        @class_attribute_writers = T.let(class_attribute_writers, T::Array[Symbol])
        @class_attribute_predicates = T.let(class_attribute_predicates, T::Array[Symbol])

        @instance_attribute_readers = T.let(instance_attribute_readers, T::Array[Symbol])
        @instance_attribute_writers = T.let(instance_attribute_writers, T::Array[Symbol])
        @instance_attribute_predicates = T.let(instance_attribute_predicates, T::Array[Symbol])
      end

      sig { returns(T::Boolean) }
      def empty_attributes?
        @class_attribute_readers.empty? && @class_attribute_writers.empty?
      end

      sig { params(tree: RBI::Tree).void }
      def compile_class_attributes(tree)
        return if empty_attributes?

        # Create a synthetic module to hold the generated class methods
        tree << RBI::Module.new("GeneratedClassMethods") do |mod|
          class_attribute_readers.each do |attribute|
            mod << RBI::Method.new(attribute.to_s)
          end

          class_attribute_writers.each do |attribute|
            mod << RBI::Method.new("#{attribute}=") do |method|
              method << RBI::ReqParam.new("value")
            end
          end

          class_attribute_predicates.each do |attribute|
            mod << RBI::Method.new("#{attribute}?")
          end
        end

        # Create a synthetic module to hold the generated instance methods
        tree << RBI::Module.new("GeneratedInstanceMethods") do |mod|
          instance_attribute_readers.each do |attribute|
            mod << RBI::Method.new(attribute.to_s)
          end

          instance_attribute_writers.each do |attribute|
            mod << RBI::Method.new("#{attribute}=") do |method|
              method << RBI::ReqParam.new("value")
            end
          end

          instance_attribute_predicates.each do |attribute|
            mod << RBI::Method.new("#{attribute}?")
          end
        end

        # Add a mixes_in_class_methods and include for the generated modules
        tree << RBI::MixesInClassMethods.new("GeneratedClassMethods")
        tree << RBI::Include.new("GeneratedInstanceMethods")
      end

      sig { params(tree: RBI::Tree).returns([T::Array[Module], T::Array[Module]]) }
      def compile_mixes_in_class_methods(tree)
        includes = dynamic_includes.filter_map do |mod|
          qname = qualified_name_of(mod)

          next if qname.nil? || qname.empty?
          next if filtered_mixin?(qname)

          tree << RBI::Include.new(qname)

          mod
        end

        # If we can generate multiple mixes_in_class_methods, then we want to use all dynamic extends that are not the
        # constant itself
        mixed_in_class_methods = dynamic_extends.select do |mod|
          mod != @constant && !module_included_by_another_dynamic_extend?(mod, dynamic_extends)
        end

        return [[], []] if mixed_in_class_methods.empty?

        mixed_in_class_methods.each do |mod|
          qualified_name = qualified_name_of(mod)

          next if qualified_name.nil? || qualified_name.empty?
          next if filtered_mixin?(qualified_name)

          tree << RBI::MixesInClassMethods.new(qualified_name)
        end

        [mixed_in_class_methods, includes]
      rescue
        [[], []] # silence errors
      end

      sig { params(mod: Module, dynamic_extends: T::Array[Module]).returns(T::Boolean) }
      def module_included_by_another_dynamic_extend?(mod, dynamic_extends)
        dynamic_extends.any? do |dynamic_extend|
          mod != dynamic_extend && ancestors_of(dynamic_extend).include?(mod)
        end
      end

      sig { params(qualified_mixin_name: String).returns(T::Boolean) }
      def filtered_mixin?(qualified_mixin_name)
        # filter T:: namespace mixins that aren't T::Props
        # T::Props and subconstants have semantic value
        qualified_mixin_name.start_with?("::T::") && !qualified_mixin_name.start_with?("::T::Props")
      end
    end
  end
end

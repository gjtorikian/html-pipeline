# typed: strict
# frozen_string_literal: true

require "set"

module Spoom
  module Deadcode
    module Plugins
      class Base
        extend T::Helpers

        abstract!

        class << self
          # Plugins DSL

          # Mark classes matching `names` as ignored.
          #
          # Names can be either strings or regexps:
          #
          # ~~~rb
          # class MyPlugin < Spoom::Deadcode::Plugins::Base
          #   ignore_class_names(
          #     "Foo",
          #     "Bar",
          #     /Baz.*/,
          #   )
          # end
          # ~~~
          #: (*(String | Regexp) names) -> void
          def ignore_classes_named(*names)
            save_names_and_patterns(names, :@ignored_class_names, :@ignored_class_patterns)
          end

          # Mark classes directly subclassing a class matching `names` as ignored.
          #
          # Names can be either strings or regexps:
          #
          # ~~~rb
          # class MyPlugin < Spoom::Deadcode::Plugins::Base
          #   ignore_classes_inheriting_from(
          #     "Foo",
          #     "Bar",
          #     /Baz.*/,
          #   )
          # end
          # ~~~
          #: (*(String | Regexp) names) -> void
          def ignore_classes_inheriting_from(*names)
            save_names_and_patterns(names, :@ignored_subclasses_of_names, :@ignored_subclasses_of_patterns)
          end

          # Mark constants matching `names` as ignored.
          #
          # Names can be either strings or regexps:
          #
          # ~~~rb
          # class MyPlugin < Spoom::Deadcode::Plugins::Base
          #   ignore_class_names(
          #     "FOO",
          #     "BAR",
          #     /BAZ.*/,
          #   )
          # end
          # ~~~
          #: (*(String | Regexp) names) -> void
          def ignore_constants_named(*names)
            save_names_and_patterns(names, :@ignored_constant_names, :@ignored_constant_patterns)
          end

          # Mark methods matching `names` as ignored.
          #
          # Names can be either strings or regexps:
          #
          # ~~~rb
          # class MyPlugin < Spoom::Deadcode::Plugins::Base
          #   ignore_method_names(
          #     "foo",
          #     "bar",
          #     /baz.*/,
          #   )
          # end
          # ~~~
          #: (*(String | Regexp) names) -> void
          def ignore_methods_named(*names)
            save_names_and_patterns(names, :@ignored_method_names, :@ignored_method_patterns)
          end

          # Mark modules matching `names` as ignored.
          #
          # Names can be either strings or regexps:
          #
          # ~~~rb
          # class MyPlugin < Spoom::Deadcode::Plugins::Base
          #   ignore_class_names(
          #     "Foo",
          #     "Bar",
          #     /Baz.*/,
          #   )
          # end
          # ~~~
          #: (*(String | Regexp) names) -> void
          def ignore_modules_named(*names)
            save_names_and_patterns(names, :@ignored_module_names, :@ignored_module_patterns)
          end

          private

          #: (Array[(String | Regexp)] names, Symbol names_variable, Symbol patterns_variable) -> void
          def save_names_and_patterns(names, names_variable, patterns_variable)
            ignored_names = instance_variable_set(names_variable, Set.new)
            ignored_patterns = instance_variable_set(patterns_variable, [])

            names.each do |name|
              case name
              when String
                ignored_names << name.delete_prefix("::")
              when Regexp
                ignored_patterns << name
              end
            end
          end
        end

        #: Index
        attr_reader :index

        #: (Index index) -> void
        def initialize(index)
          @index = index
        end

        # Indexing event methods

        # Called when an accessor is defined.
        #
        # Will be called when the indexer processes a `attr_reader`, `attr_writer` or `attr_accessor` node.
        # Note that when this method is called, the definition for the node has already been added to the index.
        # It is still possible to ignore it from the plugin:
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_define_accessor(definition)
        #     @index.ignore(definition) if symbol_def.name == "foo"
        #   end
        # end
        # ~~~
        #: (Model::Attr definition) -> void
        def on_define_accessor(definition)
          # no-op
        end

        # Do not override this method, use `on_define_accessor` instead.
        #: (Model::Attr definition) -> void
        def internal_on_define_accessor(definition)
          on_define_accessor(definition)
        end

        # Called when a class is defined.
        #
        # Will be called when the indexer processes a `class` node.
        # Note that when this method is called, the definition for the node has already been added to the index.
        # It is still possible to ignore it from the plugin:
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_define_class(definition)
        #     @index.ignore(definition) if definition.name == "Foo"
        #   end
        # end
        # ~~~
        #: (Model::Class definition) -> void
        def on_define_class(definition)
          # no-op
        end

        # Do not override this method, use `on_define_class` instead.
        #: (Model::Class definition) -> void
        def internal_on_define_class(definition)
          if ignored_class_name?(definition.name)
            @index.ignore(definition)
          elsif ignored_subclass?(definition)
            @index.ignore(definition)
          end

          on_define_class(definition)
        end

        # Called when a constant is defined.
        #
        # Will be called when the indexer processes a `CONST =` node.
        # Note that when this method is called, the definition for the node has already been added to the index.
        # It is still possible to ignore it from the plugin:
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_define_constant(definition)
        #     @index.ignore(definition) if definition.name == "FOO"
        #   end
        # end
        # ~~~
        #: (Model::Constant definition) -> void
        def on_define_constant(definition)
          # no-op
        end

        # Do not override this method, use `on_define_constant` instead.
        #: (Model::Constant definition) -> void
        def internal_on_define_constant(definition)
          @index.ignore(definition) if ignored_constant_name?(definition.name)

          on_define_constant(definition)
        end

        # Called when a method is defined.
        #
        # Will be called when the indexer processes a `def` or `defs` node.
        # Note that when this method is called, the definition for the node has already been added to the index.
        # It is still possible to ignore it from the plugin:
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_define_method(definition)
        #     @index.ignore(definition) if definition.name == "foo"
        #   end
        # end
        # ~~~
        #: (Model::Method definition) -> void
        def on_define_method(definition)
          # no-op
        end

        # Do not override this method, use `on_define_method` instead.
        #: (Model::Method definition) -> void
        def internal_on_define_method(definition)
          @index.ignore(definition) if ignored_method_name?(definition.name)

          on_define_method(definition)
        end

        # Called when a module is defined.
        #
        # Will be called when the indexer processes a `module` node.
        # Note that when this method is called, the definition for the node has already been added to the index.
        # It is still possible to ignore it from the plugin:
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_define_module(definition)
        #     @index.ignore(definition) if definition.name == "Foo"
        #   end
        # end
        # ~~~
        #: (Model::Module definition) -> void
        def on_define_module(definition)
          # no-op
        end

        # Do not override this method, use `on_define_module` instead.
        #: (Model::Module definition) -> void
        def internal_on_define_module(definition)
          @index.ignore(definition) if ignored_module_name?(definition.name)

          on_define_module(definition)
        end

        # Called when a send is being processed
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_send(send)
        #     return unless send.name == "dsl_method"
        #     return if send.args.empty?
        #
        #     method_name = send.args.first.slice.delete_prefix(":")
        #     @index.reference_method(method_name, send.node, send.loc)
        #   end
        # end
        # ~~~
        #: (Send send) -> void
        def on_send(send)
          # no-op
        end

        private

        # DSL support

        #: (Model::Namespace definition, String superclass_name) -> bool
        def subclass_of?(definition, superclass_name)
          superclass_symbol = @index.model.symbols[superclass_name]
          return false unless superclass_symbol

          @index.model.symbols_hierarchy.edge?(definition.symbol, superclass_symbol)
        end

        #: (String? name) -> bool
        def ignored_class_name?(name)
          return false unless name

          ignored_name?(name, :@ignored_class_names, :@ignored_class_patterns)
        end

        #: (Model::Class definition) -> bool
        def ignored_subclass?(definition)
          superclass_name = definition.superclass_name
          return true if superclass_name && ignored_name?(
            superclass_name,
            :@ignored_subclasses_of_names,
            :@ignored_subclasses_of_patterns,
          )

          names(:@ignored_subclasses_of_names).any? { |superclass_name| subclass_of?(definition, superclass_name) }
        end

        #: (String name) -> bool
        def ignored_constant_name?(name)
          ignored_name?(name, :@ignored_constant_names, :@ignored_constant_patterns)
        end

        #: (String name) -> bool
        def ignored_method_name?(name)
          ignored_name?(name, :@ignored_method_names, :@ignored_method_patterns)
        end

        #: (String name) -> bool
        def ignored_module_name?(name)
          ignored_name?(name, :@ignored_module_names, :@ignored_module_patterns)
        end

        #: (String name, Symbol names_variable, Symbol patterns_variable) -> bool
        def ignored_name?(name, names_variable, patterns_variable)
          names(names_variable).include?(name) || patterns(patterns_variable).any? { |pattern| pattern.match?(name) }
        end

        #: (Symbol const) -> Set[String]
        def names(const)
          self.class.instance_variable_get(const) || Set.new
        end

        #: (Symbol const) -> Array[Regexp]
        def patterns(const)
          self.class.instance_variable_get(const) || []
        end

        # Plugin utils

        #: (String name) -> String
        def camelize(name)
          name = T.must(name.split("::").last)
          name = T.must(name.split("/").last)
          name = name.gsub(/[^a-zA-Z0-9_]/, "")
          name = name.sub(/^[a-z\d]*/, &:capitalize)
          name = name.gsub(%r{(?:_|(/))([a-z\d]*)}) do
            s1 = Regexp.last_match(1)
            s2 = Regexp.last_match(2)
            "#{s1}#{s2&.capitalize}"
          end
          name
        end
      end
    end
  end
end

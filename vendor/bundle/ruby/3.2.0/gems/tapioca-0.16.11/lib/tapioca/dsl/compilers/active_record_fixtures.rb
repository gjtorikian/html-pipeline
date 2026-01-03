# typed: strict
# frozen_string_literal: true

return unless defined?(Rails) &&
  defined?(ActiveSupport::TestCase) &&
  defined?(ActiveRecord::TestFixtures)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordFixtures` decorates RBIs for test fixture methods
      # that are created dynamically by Rails.
      #
      # For example, given an application with a posts table, we can have a fixture file
      #
      # ~~~yaml
      # first_post:
      #   author: John
      #   title: My post
      # ~~~
      #
      # Rails will allow us to invoke `posts(:first_post)` in tests to get the fixture record.
      # The generated RBI by this compiler will produce the following
      #
      # ~~~rbi
      # # test_case.rbi
      # # typed: true
      # class ActiveSupport::TestCase
      #   sig { params(fixture_name: NilClass, other_fixtures: NilClass).returns(T::Array[Post]) }
      #   sig { params(fixture_name: T.any(String, Symbol), other_fixtures: NilClass).returns(Post) }
      #   sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol))
      #           .returns(T::Array[Post]) }
      #   def posts(fixture_name = nil, *other_fixtures); end
      # end
      # ~~~
      class ActiveRecordFixtures < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(ActiveSupport::TestCase) } }
        MISSING = Object.new

        sig { override.void }
        def decorate
          method_names = if fixture_loader.respond_to?(:fixture_sets)
            method_names_from_lazy_fixture_loader
          else
            method_names_from_eager_fixture_loader
          end

          method_names.select! { |name| fixture_class_mapping_from_fixture_files[name] != MISSING }
          return if method_names.empty?

          root.create_path(constant) do |mod|
            method_names.each do |name|
              create_fixture_method(mod, name.to_s)
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            return [] unless defined?(Rails.application) && Rails.application

            [ActiveSupport::TestCase]
          end
        end

        private

        sig { returns(T::Class[ActiveRecord::TestFixtures]) }
        def fixture_loader
          @fixture_loader ||= T.let(
            Class.new do
              T.unsafe(self).include(ActiveRecord::TestFixtures)

              if respond_to?(:fixture_paths=)
                T.unsafe(self).fixture_paths = [Rails.root.join("test", "fixtures")]
              else
                T.unsafe(self).fixture_path = Rails.root.join("test", "fixtures")
              end

              # https://github.com/rails/rails/blob/7c70791470fc517deb7c640bead9f1b47efb5539/activerecord/lib/active_record/test_fixtures.rb#L46
              singleton_class.define_method(:file_fixture_path) do
                Rails.root.join("test", "fixtures", "files")
              end

              T.unsafe(self).fixtures(:all)
            end,
            T.nilable(T::Class[ActiveRecord::TestFixtures]),
          )
        end

        sig { returns(T::Array[String]) }
        def method_names_from_lazy_fixture_loader
          T.unsafe(fixture_loader).fixture_sets.keys
        end

        sig { returns(T::Array[String]) }
        def method_names_from_eager_fixture_loader
          fixture_loader.ancestors # get all ancestors from class that includes AR fixtures
            .drop(1) # drop the anonymous class itself from the array
            .reject(&:name) # only collect anonymous ancestors because fixture methods are always on an anonymous module
            .flat_map do |mod|
              mod.private_instance_methods(false).map(&:to_s) + mod.instance_methods(false).map(&:to_s)
            end
        end

        sig { params(mod: RBI::Scope, name: String).void }
        def create_fixture_method(mod, name)
          return_type = return_type_for_fixture(name)
          mod.create_method(name) do |node|
            node.add_opt_param("fixture_name", "nil")
            node.add_rest_param("other_fixtures")

            node.add_sig do |sig|
              sig.add_param("fixture_name", "NilClass")
              sig.add_param("other_fixtures", "NilClass")
              sig.return_type = "T::Array[#{return_type}]"
            end

            node.add_sig do |sig|
              sig.add_param("fixture_name", "T.any(String, Symbol)")
              sig.add_param("other_fixtures", "NilClass")
              sig.return_type = return_type
            end

            node.add_sig do |sig|
              sig.add_param("fixture_name", "T.any(String, Symbol)")
              sig.add_param("other_fixtures", "T.any(String, Symbol)")
              sig.return_type = "T::Array[#{return_type}]"
            end
          end
        end

        sig { params(fixture_name: String).returns(String) }
        def return_type_for_fixture(fixture_name)
          fixture_class_mapping_from_fixture_files[fixture_name] ||
            fixture_class_from_fixture_set(fixture_name) ||
            fixture_class_from_active_record_base_class_mapping[fixture_name] ||
            "T.untyped"
        end

        sig { params(fixture_name: String).returns(T.nilable(String)) }
        def fixture_class_from_fixture_set(fixture_name)
          # only rails 7.1+ support fixture sets so this is conditional
          return unless fixture_loader.respond_to?(:fixture_sets)

          model_name_from_fixture_set = T.unsafe(fixture_loader).fixture_sets[fixture_name]
          return unless model_name_from_fixture_set

          model_name = ActiveRecord::FixtureSet.default_fixture_model_name(model_name_from_fixture_set)
          return unless Object.const_defined?(model_name)

          model_name
        end

        sig { returns(T::Hash[String, String]) }
        def fixture_class_from_active_record_base_class_mapping
          @fixture_class_mapping ||= T.let(
            begin
              ActiveRecord::Base.descendants.each_with_object({}) do |model_class, mapping|
                class_name = model_class.name

                fixture_name = class_name.underscore.gsub("/", "_")
                fixture_name = fixture_name.pluralize if ActiveRecord::Base.pluralize_table_names

                mapping[fixture_name] = class_name

                mapping
              end
            end,
            T.nilable(T::Hash[String, String]),
          )
        end

        sig { returns(T::Hash[String, String]) }
        def fixture_class_mapping_from_fixture_files
          @fixture_file_class_mapping ||= T.let(
            begin
              fixture_paths = if T.unsafe(fixture_loader).respond_to?(:fixture_paths)
                T.unsafe(fixture_loader).fixture_paths
              else
                T.unsafe(fixture_loader).fixture_path
              end

              Array(fixture_paths).each_with_object({}) do |path, mapping|
                Dir["#{path}{.yml,/{**,*}/*.yml}"].select do |file|
                  next unless ::File.file?(file)

                  ActiveRecord::FixtureSet::File.open(file) do |fh|
                    fixture_name = file.delete_prefix(path.to_s).delete_prefix("/").delete_suffix(".yml")
                    next unless fh.model_class

                    mapping[fixture_name] = fh.model_class
                  rescue ActiveRecord::Fixture::FormatError
                    # For fixtures that are not associated to any models and just contain raw data or fixtures that
                    # contain invalid formatting, we want to skip them and avoid crashing
                    mapping[fixture_name] = MISSING
                  end
                end
              end
            end,
            T.nilable(T::Hash[String, String]),
          )
        end
      end
    end
  end
end

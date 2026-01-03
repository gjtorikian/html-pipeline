# typed: strict
# frozen_string_literal: true

return unless defined?(Google::Protobuf)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Protobuf` decorates RBI files for subclasses of
      # [`Google::Protobuf::MessageExts`](https://github.com/protocolbuffers/protobuf/tree/master/ruby).
      #
      # For example, with the following "cart.rb" file:
      #
      # ~~~rb
      # Google::Protobuf::DescriptorPool.generated_pool.build do
      #   add_file("cart.proto", :syntax => :proto3) do
      #     add_message "MyCart" do
      #       optional :shop_id, :int32, 1
      #       optional :customer_id, :int64, 2
      #       optional :number_value, :double, 3
      #       optional :string_value, :string, 4
      #     end
      #   end
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `cart.rbi` with the following content:
      #
      # ~~~rbi
      # # cart.rbi
      # # typed: strong
      # class Cart < Google::Protobuf::AbstractMessage
      #   sig { returns(Integer) }
      #   def customer_id; end
      #
      #   sig { params(value: Integer).returns(Integer) }
      #   def customer_id=(value); end
      #
      #   sig { returns(Integer) }
      #   def shop_id; end
      #
      #   sig { params(value: Integer).returns(Integer) }
      #   def shop_id=(value); end
      #
      #   sig { returns(String) }
      #   def string_value; end
      #
      #   sig { params(value: String).returns(String) }
      #   def string_value=(value); end
      #
      #
      #   sig { returns(Float) }
      #   def number_value; end
      #
      #   sig { params(value: Float).returns(Float) }
      #   def number_value=(value); end
      # end
      # ~~~
      #
      # Please note that you might have to ignore the originally generated Protobuf Ruby files
      # to avoid _Redefining constant_ issues when doing type checking.
      # Do this by extending your Sorbet config file:
      #
      # ~~~
      # --ignore=/path/to/proto/cart_pb.rb
      # ~~~
      class Protobuf < Compiler
        class Field < T::Struct
          prop :name, String
          prop :type, String
          prop :init_type, String
          prop :default, String
        end

        extend T::Sig

        ConstantType = type_member { { fixed: T::Class[T.anything] } }

        FIELD_RE = /^[a-z_][a-zA-Z0-9_]*$/

        sig { override.void }
        def decorate
          root.create_path(constant) do |klass|
            if constant == Google::Protobuf::RepeatedField
              create_type_members(klass, "Elem")
            elsif constant == Google::Protobuf::Map
              create_type_members(klass, "Key", "Value")
            else
              descriptor = T.unsafe(constant).descriptor

              case descriptor
              when Google::Protobuf::EnumDescriptor
                descriptor.to_h.each do |sym, val|
                  # For each enum value, create a namespaced constant on the root rather than an un-namespaced
                  # constant within the class. This is because un-namespaced constants might conflict with reserved
                  # Ruby words, such as "BEGIN." By namespacing them, we avoid this problem.
                  #
                  # Invalid syntax:
                  # class Foo
                  #   BEGIN = 3
                  # end
                  #
                  # Valid syntax:
                  # Foo::BEGIN = 3
                  root.create_constant("#{constant}::#{sym}", value: val.to_s)
                end

                klass.create_method(
                  "lookup",
                  parameters: [create_param("number", type: "Integer")],
                  return_type: "T.nilable(Symbol)",
                  class_method: true,
                )
                klass.create_method(
                  "resolve",
                  parameters: [create_param("symbol", type: "Symbol")],
                  return_type: "T.nilable(Integer)",
                  class_method: true,
                )
                klass.create_method(
                  "descriptor",
                  return_type: "Google::Protobuf::EnumDescriptor",
                  class_method: true,
                )
              when Google::Protobuf::Descriptor
                raise "#{klass} is not a RBI::Class" unless klass.is_a?(RBI::Class)

                klass.superclass_name = "Google::Protobuf::AbstractMessage"
                descriptor.each_oneof { |oneof| create_oneof_method(klass, oneof) }
                fields = descriptor.map { |desc| create_descriptor_method(klass, desc) }
                fields.sort_by!(&:name)

                parameters = fields.map do |field|
                  create_kw_opt_param(field.name, type: field.init_type, default: field.default)
                end

                if fields.all? { |field| FIELD_RE.match?(field.name) }
                  klass.create_method("initialize", parameters: parameters, return_type: "void")
                else
                  # One of the fields has an incorrect name for a named parameter so creating the default initialize for
                  # it would create a RBI with a syntax error.
                  # The workaround is to create an initialize that takes a **kwargs instead.
                  kwargs_parameter = create_kw_rest_param("fields", type: "T.untyped")
                  klass.create_method("initialize", parameters: [kwargs_parameter], return_type: "void")
                end
              else
                add_error(<<~MSG.strip)
                  Unexpected descriptor class `#{descriptor.class.name}` for `#{constant}`
                MSG
              end
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            marker = Google::Protobuf::MessageExts::ClassMethods

            enum_modules = ObjectSpace.each_object(Google::Protobuf::EnumDescriptor).map(&:enummodule)

            results = if Google::Protobuf.const_defined?(:AbstractMessage)
              abstract_message_const = ::Google::Protobuf.const_get(:AbstractMessage)
              descendants_of(abstract_message_const) - [abstract_message_const]
            else
              T.cast(
                ObjectSpace.each_object(marker).to_a,
                T::Array[Module],
              )
            end

            results = results.concat(enum_modules)
            results.any? ? results + [Google::Protobuf::RepeatedField, Google::Protobuf::Map] : []
          end
        end

        private

        sig { params(desc: Google::Protobuf::FieldDescriptor).returns(T::Boolean) }
        def has_presence?(desc)
          if desc.respond_to?(:has_presence?)
            # This method is only defined in google-protobuf 3.26.0 and later
            desc.has_presence?
          else
            # In older versions of the gem, the only way we can get this information is
            # by checking if an instance of the class responds to the expected method
            T.unsafe(constant.allocate).respond_to?("has_#{desc.name}?")
          end
        end

        sig { params(klass: RBI::Scope, names: String).void }
        def create_type_members(klass, *names)
          klass.create_extend("T::Generic")

          names.each do |name|
            klass.create_type_variable(name, type: "type_member")
          end
        end

        sig do
          params(
            descriptor: Google::Protobuf::FieldDescriptor,
          ).returns(String)
        end
        def type_of(descriptor)
          case descriptor.type
          when :enum
            # According to https://developers.google.com/protocol-buffers/docs/reference/ruby-generated#enum
            # > You may assign either a number or a symbol to an enum field.
            # > When reading the value back, it will be a symbol if the enum
            # > value is known, or a number if it is unknown. Since proto3 uses
            # > open enum semantics, any number may be assigned to an enum
            # > field, even if it was not defined in the enum.
            "T.any(Symbol, Integer)"
          when :message
            descriptor.subtype.msgclass.name || "T.untyped"
          when :int32, :int64, :uint32, :uint64
            "Integer"
          when :double, :float
            "Float"
          when :bool
            "T::Boolean"
          when :string, :bytes
            "String"
          else
            "T.untyped"
          end
        end

        sig { params(descriptor: Google::Protobuf::FieldDescriptor).returns(T::Boolean) }
        def nilable_descriptor?(descriptor)
          descriptor.label == :optional && descriptor.type == :message
        end

        sig { params(descriptor: Google::Protobuf::FieldDescriptor).returns(T::Boolean) }
        def map_type?(descriptor)
          # Defensively make sure that we are dealing with a repeated field
          return false unless descriptor.label == :repeated

          # Try to create a new instance with the field that maps to the descriptor name
          # being assigned a hash value. If this goes through, then it's a map type.
          constant.new(**{ descriptor.name => {} })
          true
        rescue ArgumentError
          # This means the descriptor is not a map type
          false
        end

        sig { params(descriptor: Google::Protobuf::FieldDescriptor).returns(Field) }
        def field_of(descriptor)
          if descriptor.label == :repeated
            if map_type?(descriptor)
              key = descriptor.subtype.lookup("key")
              value = descriptor.subtype.lookup("value")

              key_type = type_of(key)
              value_type = type_of(value)
              type = "Google::Protobuf::Map[#{key_type}, #{value_type}]"

              Field.new(
                name: descriptor.name,
                type: type,
                init_type: "T.nilable(T.any(#{type}, T::Hash[#{key_type}, #{value_type}]))",
                default: "T.unsafe(nil)",
              )
            else
              elem_type = type_of(descriptor)
              type = "Google::Protobuf::RepeatedField[#{elem_type}]"

              Field.new(
                name: descriptor.name,
                type: type,
                init_type: "T.nilable(T.any(#{type}, T::Array[#{elem_type}]))",
                default: "T.unsafe(nil)",
              )
            end
          else
            type = type_of(descriptor)
            nilable_type = as_nilable_type(type)
            type = nilable_type if nilable_descriptor?(descriptor)

            Field.new(
              name: descriptor.name,
              type: type,
              init_type: nilable_type,
              default: "nil",
            )
          end
        end

        sig do
          params(
            klass: RBI::Scope,
            desc: Google::Protobuf::FieldDescriptor,
          ).returns(Field)
        end
        def create_descriptor_method(klass, desc)
          field = field_of(desc)

          klass.create_method(
            field.name,
            return_type: field.type,
          )

          klass.create_method(
            "#{field.name}=",
            parameters: [create_param("value", type: field.type)],
            return_type: "void",
          )

          klass.create_method(
            "clear_#{field.name}",
            return_type: "void",
          )

          if has_presence?(desc)
            klass.create_method(
              "has_#{field.name}?",
              return_type: "Object",
            )
          end

          field
        end

        sig do
          params(
            klass: RBI::Scope,
            desc: Google::Protobuf::OneofDescriptor,
          ).void
        end
        def create_oneof_method(klass, desc)
          klass.create_method(
            desc.name,
            return_type: "T.nilable(Symbol)",
          )
        end
      end
    end
  end
end

# typed: strict
# frozen_string_literal: true

return unless defined?(Time.current) && defined?(ActiveSupport::TimeWithZone)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveSupportTimeExt` generates an RBI file for the `Time#current` method
      # defined by [Active Support's Time extensions](https://api.rubyonrails.org/classes/Time.html).
      #
      # If `Time.zone` or `config.time_zone` are set, then the `Time.current` method will be defined as returning
      # an instance of `ActiveSupport::TimeWithZone`, otherwise it will return an instance of `Time`.
      #
      # For an application that is configured with:
      # ```ruby
      # config.time_zone = "UTC"
      # ```
      # this compiler will produce the following RBI file:
      # ```rbi
      # class Time
      #   class << self
      #     sig { returns(::ActiveSupport::TimeWithZone) }
      #     def current; end
      #   end
      # end
      # ```
      # whereas if `Time.zone` and `config.time_zone` are not set, it will produce:
      # ```rbi
      # class Time
      #   class << self
      #     sig { returns(::Time) }
      #     def current; end
      #   end
      # end
      # ```
      class ActiveSupportTimeExt < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::Time) } }

        sig { override.void }
        def decorate
          return unless constant.respond_to?(:zone)

          root.create_path(constant) do |mod|
            return_type = if ::Time.zone
              "::ActiveSupport::TimeWithZone"
            else
              "::Time"
            end

            mod.create_method("current", return_type: return_type, class_method: true)
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            [::Time]
          end
        end
      end
    end
  end
end

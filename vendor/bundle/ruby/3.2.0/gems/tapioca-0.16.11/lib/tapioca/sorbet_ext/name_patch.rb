# typed: true
# frozen_string_literal: true

module T
  module Types
    class Simple
      module NamePatch
        NAME_METHOD = T.let(Module.instance_method(:name), UnboundMethod)

        def name
          # Sorbet memoizes this method into the `@name` instance variable but
          # doing so means that types get memoized before this patch is applied
          qualified_name_of(@raw_type)
        end

        def qualified_name_of(constant)
          name = NAME_METHOD.bind_call(constant)
          name = nil if name&.start_with?("#<")
          return if name.nil?

          if name.start_with?("::")
            name
          else
            "::#{name}"
          end
        end
      end

      prepend NamePatch
    end
  end
end

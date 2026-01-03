# typed: strict
# frozen_string_literal: true

# This is in an rbi so the runtime doesn't depend on experimental sorbet features
module YARDSorbet::Handlers::StructClassHandler
  requires_ancestor { YARD::Handlers::Ruby::ClassHandler }
end

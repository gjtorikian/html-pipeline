# typed: strong
# frozen_string_literal: true

module YARDSorbet
  # Custom YARD Handlers
  # @see https://rubydoc.info/gems/yard/YARD/Handlers/Base YARD Base Handler documentation
  module Handlers; end
end

require_relative 'handlers/abstract_dsl_handler'
require_relative 'handlers/enums_handler'
require_relative 'handlers/include_handler'
require_relative 'handlers/mixes_in_class_methods_handler'
require_relative 'handlers/sig_handler'
require_relative 'handlers/struct_class_handler'
require_relative 'handlers/struct_prop_handler'

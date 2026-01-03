# typed: strict
# frozen_string_literal: true

require "stringio"
require "rbs"

module RBI
  class Error < StandardError; end
end

require "rbi/loc"
require "rbi/model"
require "rbi/type"
require "rbi/visitor"
require "rbi/index"

require "rbi/rbs/method_type_translator"
require "rbi/rbs/type_translator"

require "rbi/rewriters/add_sig_templates"
require "rbi/rewriters/annotate"
require "rbi/rewriters/deannotate"
require "rbi/rewriters/filter_versions"
require "rbi/rewriters/flatten_singleton_methods"
require "rbi/rewriters/flatten_visibilities"
require "rbi/rewriters/merge_trees"
require "rbi/rewriters/nest_non_public_members"
require "rbi/rewriters/nest_singleton_methods"
require "rbi/rewriters/nest_top_level_members"
require "rbi/rewriters/group_nodes"
require "rbi/rewriters/remove_known_definitions"
require "rbi/rewriters/attr_to_methods"
require "rbi/rewriters/sort_nodes"
require "rbi/rewriters/translate_rbs_sigs"
require "rbi/parser"
require "rbi/type_parser"
require "rbi/type_visitor"
require "rbi/printer"
require "rbi/rbs_printer"
require "rbi/formatter"
require "rbi/version"

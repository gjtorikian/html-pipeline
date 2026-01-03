# typed: true
# frozen_string_literal: true

module Tapioca
  module Commands
    autoload :Command, "tapioca/commands/command"
    autoload :CommandWithoutTracker, "tapioca/commands/command_without_tracker"
    autoload :Annotations, "tapioca/commands/annotations"
    autoload :CheckShims, "tapioca/commands/check_shims"
    autoload :AbstractDsl, "tapioca/commands/abstract_dsl"
    autoload :DslCompilerList, "tapioca/commands/dsl_compiler_list"
    autoload :DslGenerate, "tapioca/commands/dsl_generate"
    autoload :DslVerify, "tapioca/commands/dsl_verify"
    autoload :Configure, "tapioca/commands/configure"
    autoload :AbstractGem, "tapioca/commands/abstract_gem"
    autoload :GemGenerate, "tapioca/commands/gem_generate"
    autoload :GemSync, "tapioca/commands/gem_sync"
    autoload :GemVerify, "tapioca/commands/gem_verify"
    autoload :Require, "tapioca/commands/require"
    autoload :Todo, "tapioca/commands/todo"
  end
end

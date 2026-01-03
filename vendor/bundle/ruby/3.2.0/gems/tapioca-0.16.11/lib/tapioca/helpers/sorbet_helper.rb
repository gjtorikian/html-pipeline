# typed: strict
# frozen_string_literal: true

module Tapioca
  module SorbetHelper
    extend T::Sig

    SORBET_GEM_SPEC = T.let(
      ::Gem::Specification.find_by_name("sorbet-static"),
      ::Gem::Specification,
    )

    SORBET_BIN = T.let(
      Pathname.new(SORBET_GEM_SPEC.full_gem_path) / "libexec" / "sorbet",
      Pathname,
    )

    SORBET_EXE_PATH_ENV_VAR = "TAPIOCA_SORBET_EXE"

    SORBET_PAYLOAD_URL = "https://github.com/sorbet/sorbet/tree/master/rbi"

    SPOOM_CONTEXT = T.let(Spoom::Context.new("."), Spoom::Context)

    FEATURE_REQUIREMENTS = T.let(
      {
        # feature_name: ::Gem::Requirement.new(">= ___"), # https://github.com/sorbet/sorbet/pull/___
      }.freeze,
      T::Hash[Symbol, ::Gem::Requirement],
    )

    sig { params(sorbet_args: String).returns(Spoom::ExecResult) }
    def sorbet(*sorbet_args)
      SPOOM_CONTEXT.srb(sorbet_args.join(" "), sorbet_bin: sorbet_path)
    end

    sig { returns(String) }
    def sorbet_path
      sorbet_path = ENV.fetch(SORBET_EXE_PATH_ENV_VAR, SORBET_BIN)
      sorbet_path = SORBET_BIN if sorbet_path.empty?
      sorbet_path.to_s.shellescape
    end

    sig { params(feature: Symbol, version: T.nilable(::Gem::Version)).returns(T::Boolean) }
    def sorbet_supports?(feature, version: nil)
      version = SORBET_GEM_SPEC.version unless version
      requirement = FEATURE_REQUIREMENTS[feature]

      Kernel.raise "Invalid Sorbet feature #{feature}" unless requirement

      requirement.satisfied_by?(version)
    end
  end
end

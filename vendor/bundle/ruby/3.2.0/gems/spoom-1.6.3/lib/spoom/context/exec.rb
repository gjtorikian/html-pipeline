# typed: strict
# frozen_string_literal: true

module Spoom
  class ExecResult < T::Struct
    const :out, String
    const :err, T.nilable(String)
    const :status, T::Boolean
    const :exit_code, Integer

    #: -> String
    def to_s
      <<~STR
        ########## STDOUT ##########
        #{out.empty? ? "<empty>" : out}
        ########## STDERR ##########
        #{err&.empty? ? "<empty>" : err}
        ########## STATUS: #{status} ##########
      STR
    end
  end

  class Context
    # Execution features for a context
    module Exec
      extend T::Helpers

      requires_ancestor { Context }

      # Run a command in this context directory
      #: (String command, ?capture_err: bool) -> ExecResult
      def exec(command, capture_err: true)
        Bundler.with_unbundled_env do
          opts = { chdir: absolute_path } #: Hash[Symbol, untyped]

          if capture_err
            out, err, status = Open3.capture3(command, opts)
            ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
          else
            out, status = Open3.capture2(command, opts)
            ExecResult.new(out: out, err: nil, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
          end
        end
      end
    end
  end
end

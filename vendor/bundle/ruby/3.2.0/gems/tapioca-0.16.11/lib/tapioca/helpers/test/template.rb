# typed: strict
# frozen_string_literal: true

module Tapioca
  module Helpers
    module Test
      module Template
        extend T::Sig
        extend T::Helpers

        requires_ancestor { Kernel }

        ERB_SUPPORTS_KVARGS = T.let(
          ::ERB.instance_method(:initialize).parameters.assoc(:key), T.nilable([Symbol, Symbol])
        )

        sig { params(selector: String).returns(T::Boolean) }
        def ruby_version(selector)
          ::Gem::Requirement.new(selector).satisfied_by?(::Gem::Version.new(RUBY_VERSION))
        end

        sig { params(selector: String).returns(T::Boolean) }
        def rails_version(selector)
          ::Gem::Requirement.new(selector).satisfied_by?(ActiveSupport.gem_version)
        end

        sig { params(src: String, trim_mode: String).returns(String) }
        def template(src, trim_mode: ">")
          erb = if ERB_SUPPORTS_KVARGS
            ::ERB.new(src, trim_mode: trim_mode)
          else
            ::ERB.new(src, nil, trim_mode)
          end

          erb.result(binding)
        end

        sig { params(str: String, indent: Integer).returns(String) }
        def indented(str, indent)
          str.lines.map! do |line|
            next line if line.chomp.empty?

            (" " * indent) + line
          end.join
        end
      end
    end
  end
end

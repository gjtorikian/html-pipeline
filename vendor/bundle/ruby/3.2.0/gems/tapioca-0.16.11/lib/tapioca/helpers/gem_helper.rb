# typed: true
# frozen_string_literal: true

module Tapioca
  module GemHelper
    extend T::Sig

    sig { params(app_dir: T.any(String, Pathname), full_gem_path: String).returns(T::Boolean) }
    def gem_in_app_dir?(app_dir, full_gem_path)
      app_dir = to_realpath(app_dir)
      full_gem_path = to_realpath(full_gem_path)

      !gem_in_bundle_path?(full_gem_path) && !gem_in_ruby_path?(full_gem_path) && path_in_dir?(full_gem_path, app_dir)
    end

    sig { params(full_gem_path: String).returns(T::Boolean) }
    def gem_in_bundle_path?(full_gem_path)
      path_in_dir?(full_gem_path, Bundler.bundle_path) || path_in_dir?(full_gem_path, Bundler.app_cache)
    end

    sig { params(full_gem_path: String).returns(T::Boolean) }
    def gem_in_ruby_path?(full_gem_path)
      path_in_dir?(full_gem_path, RbConfig::CONFIG["rubylibprefix"])
    end

    sig { params(path: T.any(String, Pathname)).returns(String) }
    def to_realpath(path)
      path_string = path.to_s
      path_string = File.realpath(path_string) if File.exist?(path_string)
      path_string
    end

    private

    sig { params(path: T.any(Pathname, String), dir: T.any(Pathname, String)).returns(T::Boolean) }
    def path_in_dir?(path, dir)
      dir = Pathname.new(dir)
      path = Pathname.new(path)

      path.ascend.any?(dir)
    end
  end
end

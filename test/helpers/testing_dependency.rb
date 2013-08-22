# Public: Methods useful for testing Filter dependencies. All methods are class
# methods and should be called on the TestingDependency class.
#
# Examples
#
#   TestingDependency.temporarily_remove_dependency_by gem_name do
#     exception = assert_raise HTML::Pipeline::Filter::MissingDependencyException do
#       load TestingDependency.filter_path_from filter_name
#     end
#   end
class TestingDependency
  # Public: Use to safely test a Filter's gem dependency error handling.
  # For a certain gem dependency, remove the gem's loaded paths and features.
  # Once these are removed, yield to a block which can assert a specific
  # exception. Once the block is finished, add back the gem's paths and
  # features to the load path and loaded features, so other tests can assert
  # Filter functionality.
  #
  # gem_name - The String of the gem's name.
  # block    - Required block which asserts gem dependency error handling.
  #
  # Examples
  #
  #   TestingDependency.temporarily_remove_dependency_by gem_name do
  #     exception = assert_raise HTML::Pipeline::Filter::MissingDependencyException do
  #       load TestingDependency.filter_path_from filter_name
  #     end
  #   end
  #
  # Returns nothing.
  def self.temporarily_remove_dependency_by(gem_name, &block)
    paths = gem_load_paths_from gem_name
    features = gem_loaded_features_from gem_name

    $LOAD_PATH.delete_if { |path| paths.include? path }
    $LOADED_FEATURES.delete_if { |feature| features.include? feature }

    yield

    $LOAD_PATH.unshift(*paths)
    $LOADED_FEATURES.unshift(*features)
  end

  # Public: Find a Filter's load path.
  #
  # gem_name - The String of the gem's name.
  #
  # Examples
  #
  #   filter_path_from("autolink_filter")
  #   # => "/Users/simeon/Projects/html-pipeline/test/helpers/../../lib/html/pipeline/autolink_filter.rb"
  #
  # Returns String of load path.
  def self.filter_path_from(filter_name)
    File.join(File.dirname(__FILE__), "..", "..", "lib", "html", "pipeline", "#{filter_name}.rb")
  end

  private
  # Internal: Find a gem's load paths.
  #
  # gem_name - The String of the gem's name.
  #
  # Examples
  #
  #   gem_load_paths_from("rinku")
  #   # => ["/Users/simeon/.rbenv/versions/1.9.3-p429/lib/ruby/gems/1.9.1/gems/rinku-1.7.3/lib"]
  #
  # Returns Array of load paths.
  def self.gem_load_paths_from(gem_name)
    $LOAD_PATH.select{ |path| /#{gem_name}/i =~ path }
  end

  # Internal: Find a gem's loaded features.
  #
  # gem_name - The String of the gem's name.
  #
  # Examples
  #
  #   gem_loaded_features_from("rinku")
  #   # => ["/Users/simeon/.rbenv/versions/1.9.3-p429/lib/ruby/gems/1.9.1/gems/rinku-1.7.3/lib/rinku.bundle",
  #        "/Users/simeon/.rbenv/versions/1.9.3-p429/lib/ruby/gems/1.9.1/gems/rinku-1.7.3/lib/rinku.rb"]
  #
  # Returns Array of loaded features.
  def self.gem_loaded_features_from(gem_name)
    # gem github-markdown has a feature "github/markdown.rb".
    # Replace gem name dashes and underscores with regexp
    # range to match all features.
    gem_name_regexp = gem_name.split(/[-_]/).join("[\/_-]")

    $LOADED_FEATURES.select{ |feature| /#{gem_name_regexp}/i =~ feature }
  end
end

require "minitest/test"

Minitest.load :focus if Minitest.respond_to? :load # MT6

class Minitest::Test    # :nodoc:
  class Focus           # :nodoc:
    VERSION = "1.4.1"   # :nodoc:
  end

  @@filtered_names = [] # :nodoc:

  def self.add_to_filter name
    @@filtered_names << "#{self}##{name}"
  end

  def self.filtered_names
    @@filtered_names
  end

  ##
  # Focus on the next test defined. Cumulative. Equivalent to
  # running with command line arg: -n /test_name|.../
  #
  #   class MyTest < Minitest::Test
  #
  #     # direct approach
  #     focus def test_method1 # will run
  #       ...
  #     end
  #
  #     # indirect approach
  #     focus
  #     def test_method2       # will run
  #       ...
  #     end
  #
  #     def test_method3       # will NOT run
  #       ...
  #     end
  #   end

  def self.focus name = nil
    if name then
      add_to_filter name
    else
      set_focus_trap
    end
  end

  ##
  # Sets a one-off method_added callback to set focus on the method
  # defined next.

  def self.set_focus_trap
    meta = class << self; self; end

    meta.send :define_method, :method_added do |name|
      add_to_filter name

      meta.send :remove_method, :method_added
    end
  end
end

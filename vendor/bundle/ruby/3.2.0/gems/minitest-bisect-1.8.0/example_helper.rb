require "minitest/autorun"

$good = true
$bomb = 0

def create_test suffix, n_methods, bad_methods = {}
  raise ArgumentError, "Bad args" if Hash === n_methods

  delay = (ENV["SLEEP"] || 0.01).to_f

  Class.new(Minitest::Test) do
    n_methods.times do |n|
      n += 1
      define_method "test_bad#{suffix}_#{n}" do
        sleep delay if delay > 0

        case bad_methods[n]
        when :flunk then
          flunk "muahahaha order dependency bug!" unless $good
        when :infect then
          $good = false
        when :fix then
          $good = true
        when :tick then
          $bomb += 1
        when Integer then
          flunk "muahahaha order dependency bug!" if $bomb >= bad_methods[n]
        else
          assert true
        end
      end
    end
  end
end

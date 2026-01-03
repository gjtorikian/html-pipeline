# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :isolate
Hoe.plugin :seattlerb
Hoe.plugin :rdoc

Hoe.add_include_dirs "../../minitest-server/dev/lib"
Hoe.add_include_dirs "../../path_expander/dev/lib"

Hoe.spec "minitest-bisect" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"
  license "MIT"

  dependency "rake", "> 0", :development
  dependency "minitest-server", "~> 1.0"
  dependency "path_expander", "~> 2.0"
end

require "rake/testtask"

Rake::TestTask.new(:badtest) do |t|
  t.test_files = Dir["badtest/test*.rb"]
end

def banner text
  puts
  puts "#" * 70
  puts "# #{text} ::"
  puts "#" * 70
  puts

  return if ENV["SLEEP"] == "0"

  print "Press return to continue "
  $stdin.gets
  puts
end

def run cmd
  sh cmd do end # block form lets it fail w/o halting rake
end

task :repro => :isolate do
  unless ENV.key? "SLEEP" then
    warn "NOTE: Defaulting to sleeping 0.01 seconds per test."
    warn "NOTE: Use SLEEP=0 to disable or any other value to simulate your tests."
  end

  ruby = "ruby -I.:lib"

  banner "Original run that causes the test order dependency bug"
  run "#{ruby} example.rb --seed 1"

  banner "Reduce the problem down to the minimal reproduction"
  run "#{ruby} bin/minitest_bisect -Ilib --seed 1 example.rb"
end

task :many => :isolate do
  unless ENV.key? "SLEEP" then
    warn "NOTE: Defaulting to sleeping 0.01 seconds per test."
    warn "NOTE: Use SLEEP=0 to disable or any other value to simulate your tests."
  end

  ruby = "ruby -I.:lib"

  banner "Original run that causes the test order dependency bug"
  run "#{ruby} ./example_many.rb --seed 2"

  banner "Reduce the problem down to the minimal reproduction"
  run "#{ruby} bin/minitest_bisect -Ilib --seed 2 example_many.rb"
end

task :inverse => :isolate do
  unless ENV.key? "SLEEP" then
    warn "NOTE: Defaulting to sleeping 0.01 seconds per test."
    warn "NOTE: Use SLEEP=0 to disable or any other value to simulate your tests."
  end

  ruby = "ruby -I.:lib"

  banner "Original run that passes (seed 1)"
  run "#{ruby} example_inverse.rb --seed 1"

  banner "Original run that *looks like* a test order dependency bug (seed 3)"
  run "#{ruby} example_inverse.rb --seed 3"

  banner "BAD bisection (tests fail by themselves) (seed 3)"
  run "#{ruby} bin/minitest_bisect -Ilib --seed 3 example_inverse.rb"

  banner "Reduce the passing run down to the minimal reproduction (seed 1)"
  run "#{ruby} bin/minitest_bisect -Ilib --seed 1 example_inverse.rb -n=/TestBad4#test_bad4_4$/"
end

# vim: syntax=ruby

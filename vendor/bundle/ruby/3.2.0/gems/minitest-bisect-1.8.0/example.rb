#!/usr/bin/env ruby -w

require_relative "example_helper"

# 800 tests, test test_bad4_4 fails if test_bad1_1 runs before it
TestBad1 = create_test 1, 100, 1 => :infect
TestBad2 = create_test 2, 100
TestBad3 = create_test 3, 100
TestBad4 = create_test 4, 100, 4 => :flunk
TestBad5 = create_test 5, 100
TestBad6 = create_test 6, 100
TestBad7 = create_test 7, 100
TestBad8 = create_test 8, 100

# seed 1 == one fail
# seed 3 == all pass

# % SLEEP=0 ruby ./example.rb --seed 1
#
# and it fails, as expected. So we run it through minitest_bisect and see:
#
#   reproducing... in 0.14 sec
#   verifying... in 0.06 sec
#   # of culprit methods: 128 in 0.08 sec
#   # of culprit methods: 64 in 0.07 sec
#   # of culprit methods: 64 in 0.07 sec
#   # of culprit methods: 32 in 0.06 sec
#   # of culprit methods: 16 in 0.06 sec
#   # of culprit methods: 8 in 0.06 sec
#   # of culprit methods: 4 in 0.06 sec
#   # of culprit methods: 4 in 0.06 sec
#   # of culprit methods: 2 in 0.06 sec
#   # of culprit methods: 1 in 0.06 sec
#
#   Minimal methods found in 10 steps:
#
#   Culprit methods: ["TestBad1#test_bad1_1", "TestBad4#test_bad4_4"]
#
#   /Users/ryan/.rubies/ruby-3.2.2/bin/ruby -Itest:lib -e 'require "././example.rb"' -- --seed 1  -n "/^(?:TestBad1#(?:test_bad1_1)|TestBad4#(?:test_bad4_4))$/"
#
#   Final reproduction:
#
#   Run options: --seed 1 -n "/^(?:TestBad1#(?:test_bad1_1)|TestBad4#(?:test_bad4_4))$/"
#
#   # Running:
#
#   .F
#
#   Finished in 0.001349s, 1482.5797 runs/s, 741.2898 assertions/s.
#
#     1) Failure:
#   TestBad4#test_bad4_4 [/Users/ryan/Work/p4/zss/src/minitest-bisect/dev/example.rb:20]:
#   muahahaha order dependency bug!
#
#   2 runs, 1 assertions, 1 failures, 0 errors, 0 skips
#
# and that's all there is to it! You now know that test_bad4_4 fails
# only when paired with test_bad1_1 before it. You can now debug the
# two methods and see what they're both modifying/dependent on.

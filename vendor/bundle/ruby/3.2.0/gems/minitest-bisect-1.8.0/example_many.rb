#!/usr/bin/env ruby -w

require_relative "example_helper"

TestBad1 = create_test 1, 100,  1 => :tick
TestBad2 = create_test 2, 100
TestBad3 = create_test 3, 100, 72 => :tick
TestBad4 = create_test 4, 100
TestBad5 = create_test 5, 100, 17 => :tick
TestBad6 = create_test 6, 100
TestBad7 = create_test 7, 100
TestBad8 = create_test 8, 100, 43 => 3

# seed 1 == all pass
# seed 2 == one fail

# % ruby example_many.rb --seed 2

# and it fails, as expected. So we run it through minitest_bisect and see:

# % ruby -Ilib bin/minitest_bisect example_many.rb --seed 2

#   reproducing... in 0.15 sec
#   verifying... in 0.06 sec
#   # of culprit methods: 256 in 0.09 sec
#   ... 82 more bisections ...
#   # of culprit methods: 3 in 0.06 sec
#
#   Minimal methods found in 84 steps:
#
#   Culprit methods: ["TestBad3#test_bad3_72", "TestBad5#test_bad5_17", "TestBad1#test_bad1_1", "TestBad8#test_bad8_43"]
#
#   /Users/ryan/.rubies/ruby-3.2.2/bin/ruby -Itest:lib -e 'require "./example_many.rb"' -- --seed 2  -n "/^(?:TestBad3#(?:test_bad3_72)|TestBad5#(?:test_bad5_17)|TestBad1#(?:test_bad1_1)|TestBad8#(?:test_bad8_43))$/"
#
#   Final reproduction:
#
#   Run options: --seed 2 -n "/^(?:TestBad3#(?:test_bad3_72)|TestBad5#(?:test_bad5_17)|TestBad1#(?:test_bad1_1)|TestBad8#(?:test_bad8_43))$/"
#
#   # Running:
#
#   ...F
#
#   Finished in 0.001404s, 2849.0028 runs/s, 712.2507 assertions/s.
#
#     1) Failure:
#   TestBad8#test_bad8_43 [/Users/ryan/Work/p4/zss/src/minitest-bisect/dev/example_many.rb:20]:
#   muahahaha order dependency bug!
#
#   4 runs, 1 assertions, 1 failures, 0 errors, 0 skips
#
# and that's all there is to it! You now know that the failing test
# fails only when paired with the other 3 tests before it. You can now
# debug the 4 methods and see what they're all modifying/dependent on.

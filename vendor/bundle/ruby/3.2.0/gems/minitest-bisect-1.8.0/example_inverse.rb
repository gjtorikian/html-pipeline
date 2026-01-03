#!/usr/bin/env ruby -w

require_relative "example_helper"

$good = false

# 800 tests, test test_bad4_4 passes if test_bad1_1 runs before it
TestBad1 = create_test 1, 100, 1 => :fix
TestBad2 = create_test 2, 100
TestBad3 = create_test 3, 100
TestBad4 = create_test 4, 100, 4 => :flunk
TestBad5 = create_test 5, 100
TestBad6 = create_test 6, 100
TestBad7 = create_test 7, 100
TestBad8 = create_test 8, 100

# seed 1 == all pass
# seed 3 == one fail

# UNLIKE the scenario spelled out in example.rb...
#
# % SLEEP=0 ruby ./example_inverse.rb --seed 1
#
# passes, but
#
# % SLEEP=0 ruby ./example_inverse.rb --seed 3
#
# has 1 failure! So we run that through minitest_bisect:
#
# % SLEEP=0 ruby -Ilib bin/minitest_bisect ./example_inverse.rb --seed 3
#
# and see:
#
#   Tests fail by themselves. This may not be an ordering issue.
#
# followed by a result that doesn't actually lead to the failure.
#
# Doing a normal run of minitest_bisect in this scenario doesn't
# detect anything actually relevant. This is because we're not dealing
# with a false *negative*, we're dealing with a false *positive*. The
# question is "what makes this test pass?". So, we run it again with
# the passing seed but this time point it at the failing test by name:
#
# % SLEEP=0 ruby -Ilib bin/minitest_bisect ./example_inverse.rb --seed 1 -n=/TestBad4#test_bad4_4$/
#
# and it outputs:
#
#   Culprit methods: ["TestBad1#test_bad1_1", "TestBad4#test_bad4_4"]

# and shows a minimized run with the 2 passing tests. You now know
# that test_bad4_4 passes only when paired with test_bad1_1 before it.
# You can now debug the two methods and see what they're both
# modifying/dependent on.

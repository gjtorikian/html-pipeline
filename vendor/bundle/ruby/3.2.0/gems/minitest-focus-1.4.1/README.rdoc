= minitest-focus

home :: https://github.com/seattlerb/minitest-focus
rdoc :: http://docs.seattlerb.org/minitest-focus

== DESCRIPTION:

Allows you to focus on a few tests with ease without having to use
command-line arguments. Good for tools like guard that don't have
enough brains to understand test output. Cf. minitest-autotest (an
example of a test runner with strong testing logic).

Inspired by https://github.com/seattlerb/minitest/issues/213

== FEATURES/PROBLEMS:

* `focus` class method allows you to specify that the next test
  defined should be run.
* Use --no-focus to temporarily disable or override with --name
  arguments.

== SYNOPSIS:

    require "minitest/autorun"
    require "minitest/focus"

    class MyTest < Minitest::Test
      def test_unrelated; ...; end       # will NOT run

      focus def test_method2; ...;  end  # will run (direct--preferred)

      focus
      def test_method; ...;  end         # will run (indirect)

      def test_method_edgecase; ...; end # will NOT run
    end

    # or, with spec-style:

    describe "MyTest2" do
      focus; it "does something"       do pass end
      focus  it("does something else") {  pass   } # block precedence needs {}
    end

== REQUIREMENTS:

* minitest 5+

== INSTALL:

* sudo gem install minitest-focus

== LICENSE:

(The MIT License)

Copyright (c) Ryan Davis, seattle.rb

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require File.expand_path('../../../test_helper', __FILE__)

# Test the interactions between the different
# filters in a Markdown pipeline (specially regarding
# the sanitize, syntax highlight and autolink filters)
context "GitHub::HTML::MarkdownPipeline" do

  def md_pipeline(text, context = {})
    GitHub::HTML::MarkdownPipeline.call(text, context)[:output]
  end

  test "basic code blocks" do
    markdown = <<-md
Shoop da woop

~~~~~~
Hello world!
~~~~~~

```
Test this tuna
```

~~~This is not code~~~
    md

    doc = md_pipeline(markdown)
    assert_equal 2, doc.search('pre/code').size
  end

  test "basic code blocks + highlighting" do
    markdown = <<-md
~~~~~~ c
int main(int argc, char *argv[])
{
    return (5 > 3) && (2 < 1);
}
~~~~~~

~~~~
This is not highlighted
~~~~
    md

    doc = md_pipeline(markdown)
    assert_equal 1, doc.search('span.k').size
  end

  test "proper escaping of code" do
    markdown = <<-md
~~~~~~ c
return (5 > 3) && (2 < 1);
~~~~~~

~~~~
return (5 > 3) && (2 < 1);
~~~~
    md

    html = md_pipeline(markdown).to_html
    assert_equal 2, html.scan('&gt;').size
    assert_equal 2, html.scan('&lt;').size
    assert_equal 4, html.scan('&amp;').size
  end

  test "autolinking works" do
    markdown = <<-md
This is http://www.pokemon.com a test
    md

    doc = md_pipeline(markdown)
    assert_equal 1, doc.search('a').size
  end

  test "autolinking doesn't work inside of highlighted code" do
    markdown = <<-md
~~~~~~~~~ python
def get_url(self):
  return "http://www.pokemon.com"
~~~~~~~~~~~~~~~~
    md

    doc = md_pipeline(markdown)
    assert_equal 0, doc.search('a').size
  end

  test "sanitizer drops invalid html tags" do
    markdown = <<-md
One more time. <style>Daft Punk</style>
    md

    doc = md_pipeline(markdown)
    assert_equal 0, doc.search('style').size
  end

  test "autolinks url with quote" do
    input = %(http://website.com/"onmouseover=document.body.style.backgroundColor="pink";//)
    output = "<p><a href=\"http://website.com/%22onmouseover=document.body.style.backgroundColor=%22pink%22;//\">http://website.com/\"onmouseover=document.body.style.backgroundColor=\"pink\";//</a></p>"
    assert_equal output, md_pipeline(input).to_html
  end
end


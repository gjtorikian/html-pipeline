require "test_helper"

class HTML::Pipeline::TableOfContentsFilterTest < Test::Unit::TestCase
  TocFilter = HTML::Pipeline::TableOfContentsFilter

  def test_anchors_are_added_properly
    orig = %(<h1>Ice cube</h1><p>Will swarm on any motherfucker in a blue uniform</p>)
    assert_includes '<a name=', TocFilter.call(orig).to_s
  end

  def test_anchors_have_sane_names
    orig = %(<h1>Dr Dre</h1><h1>Ice Cube</h1><h1>Eazy-E</h1><h1>MC Ren</h1>)
    result = TocFilter.call(orig).to_s

    assert_includes '"dr-dre"', result
    assert_includes '"ice-cube"', result
    assert_includes '"eazy-e"', result
    assert_includes '"mc-ren"', result
  end

  def test_dupe_headers_have_unique_trailing_identifiers
    orig = %(<h1>Straight Outta Compton</h1>
             <h2>Dopeman</h2>
             <h3>Express Yourself</h3>
             <h1>Dopeman</h1>)

    result = TocFilter.call(orig).to_s

    assert_includes '"dopeman"', result
    assert_includes '"dopeman-1"', result
  end

  def test_all_header_tags_are_found_when_adding_anchors
    orig = %(<h1>"Funky President" by James Brown</h1>
             <h2>"It's My Thing" by Marva Whitney</h2>
             <h3>"Boogie Back" by Roy Ayers</h3>
             <h4>"Feel Good" by Fancy</h4>
             <h5>"Funky Drummer" by James Brown</h5>
             <h6>"Ruthless Villain" by Eazy-E</h6>
             <h7>"Be Thankful for What You Got" by William DeVaughn</h7>)

    doc = TocFilter.call(orig)
    assert_equal 6, doc.search('a').size
  end
end



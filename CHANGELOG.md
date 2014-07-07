# CHANGELOG

## 1.9.0

  * Generalize https filter with :base_url #124 #131 rymohr
  * Clean up gemspec dependencies #130 mislav
  * EmojiFilter compatibility with gemoji v2 #129 mislav
  * Now using Minitest #126 simeonwillbanks

## 1.8.0

  * Add custom path support for EmojiFilter #122 bradly
  * Reorganize README and add table of contents #118 simeonwillbanks

## 1.7.0

  * SanitizationFilter whitelists <s> and <strike> elements #120 charliesome
  * ruby 2.1.1 support #119 simeonwillbanks

## 1.6.0

  * Doc update for syntax highlighting #108 simeonwillbanks
  * Add missing dependency for EmailReplyFilter #110 foca
  * Fix deprecation warning for Digest::Digest #103 chrishunt

## 1.5.0

  * More flexible whitelist configuration for SanitizationFilter #98 aroben

## 1.4.0

  * Fix CamoFilter double entity encoding. #101 josh

## 1.3.0

1.2.0 didn't actually include the following changes. Yanked that release.

  * CamoFilter now camos https images. #96 josh

## 1.1.0

  * escape emoji filenames in urls #92 jayroh

## 1.0.0

To upgrade to this release, you will need to include separate gems for each of
the filters. See [this section of the README](/README.md#dependencies) for
details.

  * filter dependencies are no longer included #80 from simeonwillbanks/simple-dependency-management
  * Add link_attr option to Autolink filter #89 from excid3/master
  * Add ActiveSupport back in as dependency for xml-mini #85 from mojavelinux/xml-mini

## 0.3.1

  * Guard against nil node replacement in SyntaxHighlightFilter #84 jbarnette

## 0.3.0

  * Add support for manually specified default language in SyntaxHighlightFilter #81 jbarnette

## 0.2.1

  * Moves ActiveSupport as a development dependency #79

## 0.2.0

  * Fix README typo #74 tricknotes
  * TableOfContentsFilter generates list of sections #75 simeonwillbanks

## 0.1.0

I realized I wasn't properly following [semver](http://semver.org) for interface
changes and new features. Starting from this release, semver will be followed.

  * Whitelist table section elements in sanitization filter #55 mojavelinux
  * Update readme typo #57 envygeeks
  * TOC unicode characters and anchor names for Ruby > 1.9 #64 jakedouglas/non_english_anchors
  * Add :skip_tags option for AutolinkFilter #65 pengwynn
  * Fix CI dependency issues #67 jch
  * Fix ignored test and add Ruby 2.0 to CI. #71, #72 tricknotes

## 0.0.14

  * Remove unused can_access_repo? method jch

## 0.0.13

  * Update icon class name (only affects TOC pipeline) cameronmcefee #52

## 0.0.12

  * add additional payload information for instrumentation mtodd #46
  * generate and link to gem docs in README

## 0.0.11

  * add instrumentation support. readme cleanup mtodd #45

## 0.0.10

  * add bin/html-pipeline util indirect #44
  * add result[:mentioned_usernames] for MentionFilter fachen #42

## 0.0.9

  * bump escape_utils ~> 0.3, github-linguist ~> 2.6.2 brianmario #41
  * remove nokogiri monkey patch for ruby >= 1.9 defunkt #40

## 0.0.8

  * raise LoadError instead of printing to stderr if linguist is missing. gjtorikian #36

## 0.0.7

  * optionally require github-linguist chrislloyd #33

## 0.0.6

  * don't mutate markdown strings: jakedouglas #32

## 0.0.5

  * fix li xss vulnerability in sanitization filter: vmg #31
  * gemspec cleanup: nbibler #23, jbarnette #24
  * doc updates: jch #16, pborreli #17, wickedshimmy #18, benubois #19, blackerby #21
  * loosen gemoji dependency: josh #15

## 0.0.4

  * initial public release

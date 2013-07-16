# CHANGELOG

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

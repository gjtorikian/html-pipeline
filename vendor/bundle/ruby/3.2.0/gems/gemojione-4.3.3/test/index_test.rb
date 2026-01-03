# encoding: UTF-8

require File.absolute_path File.dirname(__FILE__) + '/test_helper'

describe Gemojione::Index do
  let(:index) { Gemojione::Index.new }

  describe "all" do
    it "return emoji_list" do
      assert index.all, index.instance_variable_get(:@emoji_by_name)
    end
  end

  describe "find_by_name" do
    it 'should find cyclone emoji' do
      assert index.find_by_name('cyclone')
    end
  end

  describe "find_by_moji" do
    it 'should find cyclone emoji by moji character' do
      assert index.find_by_moji('🌀')
    end
  end

  describe "find_by_keyword" do
    it 'should find all emoji with glasses keyword' do
      glasses_emoji = index.find_by_keyword('glasses')
      assert glasses_emoji
      assert glasses_emoji.length == 5
      glasses_emoji.each do |emoji_hash|
        assert_includes(emoji_hash['keywords'], 'glasses')
      end
    end
  end

  describe 'find by ascii' do
    it 'returns the heart emoji' do
      assert index.find_by_ascii('<3')['unicode'] == "2764"
    end
  end
  
  describe 'find by shortname' do
    it 'returns the heart emoji' do
      assert index.find_by_shortname(':heart:')['unicode'] == '2764'
    end
  end

  describe 'find by category' do
    it 'should find people category by category name' do
      assert index.find_by_category('people')
    end
  end

  describe "unicode_moji_regex" do
    it "should return complex moji regex" do
      regex = index.unicode_moji_regex

      assert "🌀".match(regex)
    end
  end
end

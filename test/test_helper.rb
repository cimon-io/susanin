$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'susanin'

require 'simplecov'
require 'pry'
require 'minitest/autorun'

SimpleCov.start do
  add_filter "/test/"
end if ENV["COVERAGE"]

module Assertions
  def assert_equal(source, target, msg=nil)
    assert(source == target, msg)
  end

  def dissuade(source, msg=nil)
    assert(source == false, msg)
  end
end

Minitest::Test.send :include, Assertions

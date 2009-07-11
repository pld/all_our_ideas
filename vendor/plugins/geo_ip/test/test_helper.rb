require 'rubygems'

Dir[File.join(File.dirname(__FILE__), '../lib/*.rb')].each { |file| require file }
require File.join(File.dirname(__FILE__), '../init.rb')

require 'test/unit'
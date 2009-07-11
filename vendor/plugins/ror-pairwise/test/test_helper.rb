require 'rubygems'
require 'activerecord'
require 'libxml'
require 'uri'
require 'net/http'

Dir[File.join(File.dirname(__FILE__), '../lib/*.rb')].each { |file| require file }
require File.join(File.dirname(__FILE__), '../init.rb')

require 'test/unit'
#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
# Test zmmylogpasswd star, stop, reload
#


#if($0 == __FILE__)
#  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
#end


if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmamavisd"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmmylogpasswd"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

 v(ZMMylogpasswd.new()) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?("this script changes zimbra_logger_myql_password") \
 end,

 v(ZMMylogpasswd.new('test123')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Changed zimbra mysql user password") \
 end,

 v(ZMMylogpasswd.new('--root','test123')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Changed mysql root user password") \
                                  && data[1].include?("Changed mysql root user password root@localhost") \
 end,
#bug 29541
# v(ZMMylogpasswd.new('-h')) do |mcaller, data|
#    mcaller.pass = (data[0] == 0) && data[1].include?("this script changes zimbra_logger_myql_password") \
# end,
#
# v(ZMMylogpasswd.new('--help')) do |mcaller, data|
#    mcaller.pass = (data[0] == 0) && data[1].include?("this script changes zimbra_logger_myql_password") \
# end,

]
#
# Tear Down
#

current.teardown = [

]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2009 Yahoo
#
# Test zmmypasswd star, stop, reload
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
current.description = "Test zmmypasswd"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

 v(ZMMypasswd.new()) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?("this script changes zimbra_myql_password")
 end,

 v(ZMMypasswd.new('test123')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Changed zimbra mysql user password")
 end,

 v(ZMMypasswd.new('--root','test123')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Changed mysql root user password") \
                                  && data[1].include?("Changed mysql root user password root@localhost")
 end,
#-h shouldnt return 1 29688
 v(ZMMypasswd.new('-h')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Usage')
    if !mcaller.pass
      mcaller.message = "Bug: 29688"
    end
 end,

 v(ZMMypasswd.new('--help')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Usage')
    if !mcaller.pass
      mcaller.message = "Bug: 29688"
    end
 end,

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

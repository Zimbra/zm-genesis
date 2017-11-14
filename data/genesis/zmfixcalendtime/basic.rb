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
# Test zmfixcalendtime basic functions
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "action/zmfixcalendtime"
require "model"



include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmfixcalendtime"
mailbox = Model::Servers.getServersRunning("mailbox").first.to_s
#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMFixcalendtime.new('-h')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('usage')
  end,

  v(ZMFixcalendtime.new('-a',"admin@#{Model::TARGETHOST}")) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMFixcalendtime.new('-a',"admin@#{Model::TARGETHOST}", '-s', mailbox)) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMFixcalendtime.new('-a',"admin@#{Model::TARGETHOST}", '-s', mailbox),'--sync') do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMFixcalendtime.new('-a',"admin@#{Model::TARGETHOST}",'--sync')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

#  v(ZMFixcalendtime.new('-a',"wrong@#{Model::TARGETHOST}")) do |mcaller, data|
#    mcaller.pass = (data[0] == 1)&& data[1].include?('Error occurred:')
#  end,

  v(ZMFixcalendtime.new('-a',"admin@#{mailbox}",'-s','test.wrongdomain.com')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && (data[1].include?('Error occurred: Unknown host:') || data[1].include?('Error occurred: connect timed out') || data[1].include?('Error occurred: Connection refused'))
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
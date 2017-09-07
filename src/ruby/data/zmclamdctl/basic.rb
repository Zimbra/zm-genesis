#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 VMWare
#
#
# Test basic zmclamdctl command
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
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
current.description = "Test zmclamdctl"

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [

  # Start -> Stop -> Status -> start -> status
  
  # Bug - 103117, clamd does not stop cleanly intermittently and hence while starting clamd it says - 
  # "Starting clamd...clamd is already running." instead of "Starting clamd...done." 
  
  v(ZMClamdctl.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && 
                   (data[1].include?("Starting clamd...done.") || data[1].include?("Starting clamd...clamd is already running."))
  end,

  v(ZMClamdctl.new('stop')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] !~ /failed/i && data[1].include?("Stopping clamd...done.")
  end,
  
  v(ZMClamdctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?("clamd is not runnning")
  end,
  
  v(ZMClamdctl.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] !~ /failed/i &&
          (data[1].include?("Starting clamd...done.") || data[1].include?("Starting clamd...clamd is already running."))
  end,
  
  v(ZMClamdctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] !~ /failed/i && data[1].include?("clamd is running.")
  end,
  
  # Kill -> Status
   
  v(ZMClamdctl.new('kill')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] !~ /failed/i
  end,  
  
  v(ZMClamdctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?("clamd is not runnning")
  end,
  
  # restart -> status
  
  v(ZMClamdctl.new('restart')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Stopping clamd...clamd is not running.") &&
                   data[1].include?("Starting clamd...done.")
  end,

  v(ZMClamdctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0
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
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
# Test basic zmconvertctl command
#
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
current.description = "Test zmconvertctl"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMConvertctl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMConvertctl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMConvertctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMConvertctl.new('restart')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  # Adding tests for bug 10692 Verifying exact status of command.
  v(ZMConvertctl.new('stop')) do |mcaller, data|
	mcaller.pass = data[0] == 0 && !data[1].include?("failed") && data[1].include?("Stopping convertd...done.") || data[1].include?("convertd is not running")
  end,
  
  v(ZMConvertctl.new('start')) do |mcaller, data|
	mcaller.pass = data[0] == 0 && !data[1].include?("failed") && data[1].include?("Starting convertd...done.")
  end,
  
  v(ZMConvertctl.new('start')) do |mcaller, data|
	mcaller.pass = data[0] == 0 && data[1].include?("already running")
  end,  
  
  v(ZMConvertctl.new('reload')) do |mcaller, data|
	mcaller.pass = data[0] == 0 && !data[1].include?("failed") && data[1].include?("Reloading convertd...done.")
  end,
  
  v(ZMConvertctl.new('restart')) do |mcaller, data|
	mcaller.pass = data[0] == 0 && !data[1].include?("failed") && data[1].include?("Stopping convertd...done.") && data[1].include?("Starting convertd...done.")
  end,
  
  v(ZMConvertctl.new('graceful')) do |mcaller, data|
	mcaller.pass = data[0] == 0 && !data[1].include?("failed") && data[1].include?("Reloading convertd...done.")
  end,
  
  v(ZMConvertctl.new('status')) do |mcaller, data|
	mcaller.pass = data[0] == 0 && !data[1].include?("failed") && data[1].include?("convertd is running.")
  end,
  # END Adding tests for bug 10692
  
  # kill does same job as stop but returns 1 on success. Need to confirm. Bug 27854
  v(ZMConvertctl.new('reload')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMConvertctl.new('reload')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMConvertctl.new('restart')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMConvertctl.new('graceful')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
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
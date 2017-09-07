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
# Test zmqstat basic functions
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
require "action/zmqstat"
require "model"



include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmqstat"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMQstat.new()) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('hold=') && data[1].include?('corrupt=')&& data[1].include?('deferred=')&& data[1].include?('active=')&& data[1].include?('incoming=')
  end,

  v(ZMQstat.new('hold')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMQstat.new('corrupt')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMQstat.new('deferred')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMQstat.new('active')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMQstat.new('incoming')) do |mcaller, data|
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
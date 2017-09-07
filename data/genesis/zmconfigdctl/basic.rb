#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author: vstamatoiu
#
# 2012 VMWare
#
# Test zmconfigdctl start, stop, restart
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
current.description = "Test zmconfigdctl"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMConfigdctl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('Starting zmconfigd...zmconfigd is already running.')
  end,

  v(ZMConfigdctl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('Starting zmconfigd...zmconfigd is already running.')
  end,

  v(ZMConfigdctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('zmconfigd is running.')
  end,

  v(ZMConfigdctl.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('Stopping zmconfigd...done.')
  end,

  v(ZMConfigdctl.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('Stopping zmconfigd...zmconfigd is not running.')
  end,

  v(ZMConfigdctl.new('restart')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('Stopping zmconfigd...zmconfigd is not running.')&& data[1].include?('Starting zmconfigd...done.')
  end,

  v(ZMConfigdctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('zmconfigd is running.')
  end,

  v(ZMConfigdctl.new('restart')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('Stopping zmconfigd...done.')&& data[1].include?('Starting zmconfigd...done.')
  end,


  v(ZMConfigdctl.new('kill')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Stopping zmconfigd...done')
  end,

  v(ZMConfigdctl.new('restart')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping zmconfigd...zmconfigd is not running.')&& data[1].include?('Starting zmconfigd...done.')
  end,

  v(ZMConfigdctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('zmconfigd is running.')
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
